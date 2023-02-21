FROM alpine:3.16

LABEL org.opencontainers.image.source="https://github.com/jbowdre/content-library-rsync"

ENV CRONTAB_FILE=/var/spool/cron/crontabs/root

EXPOSE 80/tcp

RUN apk add --no-cache \
    caddy \
    openssh-client \
    python3 \
    rsync \
    tzdata

RUN mkdir /syncer

COPY ./Caddyfile /etc/caddy/Caddyfile
COPY ./update_library_manifests.py /syncer/
COPY ./sync.sh /syncer/
COPY ./entrypoint.sh /

RUN chmod +x /entrypoint.sh \
    && chmod +x /syncer/sync.sh \
    && rm -rf /tmp/*

VOLUME ["/syncer/library", "/syncer/.ssh"]

ENTRYPOINT [ "/entrypoint.sh" ]
CMD [ "sh", "-c", "crond -l 2 -f" ]
