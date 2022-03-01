#!/bin/bash -e

export ARTIFACT_NAME=$1
export BUILD_ID="ga-${GITHUB_RUN_NUMBER}"
export DOCKER_TARGET="${ECR_REPO}/${ARTIFACT_NAME}:${BUILD_ID}"
ARTIFACT_DEST_PATH="/opt/tomcat/webapps/"

find ${DOCKER_BUILD_DIR}

cp ci-tools/build/Dockerfile ${DOCKER_BUILD_DIR}/Dockerfile
sed -i -e "s|BASEIMAGE|${ECR_REPO}/${BASE_IMAGE}|g" ${DOCKER_BUILD_DIR}/Dockerfile

if [ "$(ls -A $DOCKER_BUILD_DIR/artifact/*.war)" ]; then 
  for artifact in $DOCKER_BUILD_DIR/artifact/*.war; do 
    unzip -qd "$DOCKER_BUILD_DIR/artifact/$(basename $artifact .war)" $artifact
    rm -f $artifact
  done
fi
docker build --build-arg name=${ARTIFACT_NAME} --build-arg artifact_destination=${ARTIFACT_DEST_PATH} -t ${DOCKER_TARGET} ${DOCKER_BUILD_DIR}

docker images
