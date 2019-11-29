FROM BASEIMAGE

ARG name
ARG artifact_destination

ADD config/ /etc/oph
ADD artifact/ $artifact_destination

RUN apk add tzdata
RUN ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

EXPOSE 8080

ENV NAME $name

# Ensure no setuid / setgid binaries exist
RUN find / -xdev -perm +6000 -type f -exec chmod a-s {} \; || true

WORKDIR /home/oph
USER oph

CMD ["bash", "/usr/local/bin/run"]
