FROM BASEIMAGE

ARG name
ARG artifact_destination

WORKDIR /root

ADD config/ /root
ADD artifact/ $artifact_destination

RUN apk add tzdata
RUN ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

EXPOSE 8080

ENV NAME $name

CMD ["sh", "/tmp/scripts/run"]
