FROM BASEIMAGE

ARG name

WORKDIR /root

RUN mkdir /tmp/scripts/

ADD config/ /root
ADD wars/ /opt/tomcat/webapps/
ADD jars/ /root
ADD run /tmp/scripts/

RUN apk add tzdata
RUN ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

EXPOSE 8080

ENV NAME $name

CMD ["sh", "/tmp/scripts/run"]
