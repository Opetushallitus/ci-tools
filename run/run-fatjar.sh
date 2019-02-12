#!/bin/bash -e
#

BASEPATH="/root"
CONFIGPATH="/etc/oph-environment"
VARS="${CONFIGPATH}/opintopolku.yml"
CERT="${CONFIGPATH}/cert/ssl.pem"
LOGPATH="${CONFIGPATH}/log"

echo "Downloading environment-specific properties"
env_config_path=${ENV_CONFIG_S3_PATH:-/services/}
env_config_version=${ENV_CONFIG_VERSION:-latest}
aws s3 cp s3://${ENV_BUCKET}${env_config_path}${env_config_version}/ ${CONFIGPATH}/ --recursive --exclude "templates/*"
cp -vr ${CONFIGPATH}/* ${BASEPATH}/oph-configuration/

echo "Overwriting with AWS-specific configs..."
for AWS_TEMPLATE in `find ${BASEPATH}/ -name "*.template.aws"`
do
  ORIGINAL_TEMPLATE=`echo ${AWS_TEMPLATE} | sed "s/\.aws//g"`
  cp -v ${AWS_TEMPLATE} ${ORIGINAL_TEMPLATE}
done

echo "Processing configuration files..."
for tpl in `find ${BASEPATH}/ -name "*.template"`
do
  target=`echo ${tpl} | sed "s/\.template//g"`
  echo "Prosessing ${tpl} -> ${target}"
  j2 ${tpl} ${VARS} > ${target}
  chmod 0755 ${target}
done

CACERTSPWD="`grep "java_cacerts_pwd" /etc/oph-environment/opintopolku.yml | grep -o -e '\".*\"' | sed 's/^\"\(.*\)\"$/\1/'`"
if [ -f "${CERT}" ]; then
  echo "Installing local certificates to Java..."
  openssl x509 -outform der -in ${CERT} -out /tmp/ssl.der
  keytool -import -noprompt -storepass ${CACERTSPWD} -alias opintopolku -keystore /opt/java/openjdk/lib/security/cacerts -file /tmp/ssl
fi

export LC_CTYPE=fi_FI.UTF-8
export JAVA_TOOL_OPTIONS='-Dfile.encoding=UTF-8'
export JMX_PORT=1133
mkdir -p /root/logs

# PP-299: This symlink is for backwards-compatibility and can be removed once no services use base-legacy image
if [ -f "/root/jmx_prometheus_javaagent-0.10.jar" ]; then
  echo "Found legacy jmx_exporter, symlinking it to a versionless name"
  ln -s /root/jmx_prometheus_javaagent-0.10.jar /root/jmx_prometheus_javaagent.jar
fi

echo "Starting Prometheus node_exporter..."
nohup /root/node_exporter > /root/node_exporter.log  2>&1 &

if [ ${DEBUG_ENABLED} == "true" ]; then
  echo "JDWP debugging enabled..."
  STANDALONE_DEBUG_PARAMS=" -Xdebug -Xrunjdwp:transport=dt_socket,address=1233,server=y,suspend=n"
  DEBUG_PARAMS=" -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=1233"
else
  echo "JDWP debugging disabled..."
  STANDALONE_DEBUG_PARAMS=""
  DEBUG_PARAMS=""
fi

echo "Using java options: ${JAVA_OPTS}"
echo "Using secret java options: ${SECRET_JAVA_OPTS}"

STANDALONE_JAR=${HOME}/${NAME}.jar
if [ -f "${STANDALONE_JAR}" ]; then
    echo "Starting standalone application..."

    # Service-specific boot-time exceptions
    if [ ${NAME} == "suoritusrekisteri" ]; then
      echo "Create common.properties"
      cp -fv ${BASEPATH}/oph-configuration/${NAME}.properties ${BASEPATH}/oph-configuration/common.properties
      YTLCERT="${CONFIGPATH}/suoritusrekisteri/ytlqa.crt"
      if [ -f "${YTLCERT}" ]; then
            echo "Installing YTL certificate for suoritusrekisteri"
            keytool -import -noprompt -trustcacerts -alias ytl_qa_cert -storepass ${CACERTSPWD} -keystore /opt/java/openjdk/lib/security/cacerts -file ${YTLCERT}
        else
            echo "YTL test certificate not found"
      fi
    elif [ ${NAME} == "virkailijan-tyopoyta" ]; then
      echo "Create common.properties"
      cp -fv ${BASEPATH}/oph-configuration/${NAME}.properties ${BASEPATH}/oph-configuration/common.properties
    elif [ ${NAME} == "ataru-hakija" ]; then
      export ATARU_HTTP_PORT=8080
      export CONFIG=/root/oph-configuration/config.edn
      export CONFIGDEFAULTS=/root/oph-configuration/config.edn
      export APP=hakija
    elif [ ${NAME} == "ataru-editori" ]; then
      export ATARU_HTTP_PORT=8080
      export CONFIG=/root/oph-configuration/config.edn
      export CONFIGDEFAULTS=/root/oph-configuration/config.edn
      export APP=virkailija
    elif [ ${NAME} == "osaan" ]; then
        echo "Running osaan database migration"
        java -jar ${HOME}/osaan-db.jar -u oph
    fi


    export HOME="/root"
    export LOGS="${HOME}/logs"

    JAVA_OPTS="$JAVA_OPTS -Duser.home=${HOME}"
    JAVA_OPTS="$JAVA_OPTS -DHOSTNAME=`hostname`"
    JAVA_OPTS="$JAVA_OPTS -Djava.security.egd=file:/dev/urandom"
    JAVA_OPTS="$JAVA_OPTS -Djava.net.preferIPv4Stack=true"
    JAVA_OPTS="$JAVA_OPTS -Dfile.encoding=UTF-8"
    JAVA_OPTS="$JAVA_OPTS -Dlogback.access=${LOGPATH}/logback-access.xml"
    JAVA_OPTS="$JAVA_OPTS -Dlogbackaccess.configurationFile=${LOGPATH}/logback-access.xml"
    if [ ${NAME} == "liiteri" ]; then
        JAVA_OPTS="$JAVA_OPTS -Dlogback.configurationFile=${LOGPATH}/logback-liiteri.xml"
    elif [ ${NAME} == "virkailijan-tyopoyta" ]; then
        JAVA_OPTS="$JAVA_OPTS -Dlogback.configurationFile=${HOME}/oph-configuration/logback.xml"
    elif [ ${NAME} == "oti" ]; then
        JAVA_OPTS="$JAVA_OPTS -Dlogback.configurationFile=${HOME}/oph-configuration/logback.xml"
    else
        # at least hakuperusteet seems to need this
        JAVA_OPTS="$JAVA_OPTS -Dlogback.configurationFile=${LOGPATH}/logback-standalone.xml"
    fi
    JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote"
    JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.authenticate=false"
    JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.ssl=false"
    JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.port=${JMX_PORT}"
    JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.rmi.port=${JMX_PORT}"
    JAVA_OPTS="$JAVA_OPTS -Dcom.sun.management.jmxremote.local.only=false"
    JAVA_OPTS="$JAVA_OPTS -Djava.rmi.server.hostname=localhost"
    JAVA_OPTS="$JAVA_OPTS -Xlog:gc*:file=${LOGS}/${NAME}_gc.log:uptime:filecount=10,filesize=10m"
    JAVA_OPTS="$JAVA_OPTS -XX:+HeapDumpOnOutOfMemoryError"
    JAVA_OPTS="$JAVA_OPTS -XX:HeapDumpPath=${HOME}/dumps/${NAME}_heap_dump-`date +%Y-%m-%d-%H-%M-%S`.hprof"
    JAVA_OPTS="$JAVA_OPTS -XX:ErrorFile=${LOGS}/${NAME}_hs_err.log"
    JAVA_OPTS="$JAVA_OPTS -D${NAME}.properties=${HOME}/oph-configuration/${NAME}.properties"
    JAVA_OPTS="$JAVA_OPTS -javaagent:/root/jmx_prometheus_javaagent.jar=1134:/root/prometheus.yaml"
    JAVA_OPTS="$JAVA_OPTS ${SECRET_JAVA_OPTS}"
    JAVA_OPTS="$JAVA_OPTS ${STANDALONE_DEBUG_PARAMS}"
    echo "java ${JAVA_OPTS} -jar ${STANDALONE_JAR}" > /root/java-cmd.txt
    java ${JAVA_OPTS} -jar ${STANDALONE_JAR}
else
  echo "Fatal error: No fatjar found, exiting!"
  exit 1
fi
