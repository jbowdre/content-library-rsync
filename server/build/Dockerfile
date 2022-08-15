FROM alpine:3.16

LABEL org.opencontainers.image.source="https://github.com/jbowdre/library-syncer"

ENV SYNC_CMD='command="/usr/bin/rrsync -ro /syncer/library/",no-agent-forwarding,no-port-forwarding,no-pty,no-user-rc,no-X11-forwarding'

RUN apk add --no-cache \
    openssh-server \
    rsync \
    rrsync \
    tzdata

RUN mkdir /syncer

USER root
COPY ./entrypoint.sh /
RUN chmod +x /entrypoint.sh \
    && rm -rf /tmp/* \
    && rm -rf /etc/ssh/ssh_host_rsa_key /etc/ssh/ssh_host_dsa_key

EXPOSE 22/tcp

VOLUME [ "/syncer/library", "/home/syncer/.ssh" ]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "/usr/sbin/sshd", "-D" ]
