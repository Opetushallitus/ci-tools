FROM BASEIMAGE

ARG name
ARG artifact_destination

ADD config/ /etc/oph
ADD artifact/ $artifact_destination

RUN ln -sf /usr/share/zoneinfo/Europe/Helsinki /etc/localtime

EXPOSE 8080

ENV NAME $name

# Ensure no setuid / setgid binaries exist
RUN find / -xdev -perm +6000 -type f -not -name sudo -exec chmod a-s {} \; || true

WORKDIR /home/oph
USER oph

CMD ["sh", "/usr/local/bin/run"]
