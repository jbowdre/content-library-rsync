#!/bin/sh
set -e

chmod 600 /syncer/.ssh/id_syncer

echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Performing initial sync..."
/syncer/sync.sh now > /proc/self/fd/1 2>/proc/self/fd/2
echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Creating cron job..."
if [ "$SYNC_DELAY" == "false" ]; then
    echo "$SYNC_SCHEDULE /syncer/sync.sh now > /proc/self/fd/1 2>/proc/self/fd/2" >> $CRONTAB_FILE
else
    echo "$SYNC_SCHEDULE /syncer/sync.sh > /proc/self/fd/1 2>/proc/self/fd/2" >> $CRONTAB_FILE
fi
chmod 0644 $CRONTAB_FILE

if [ "$TLS_NAME" != "" ]; then
    if [ "$TLS_CUSTOM_CERT" == "true" ]; then
        cat << EOF > /etc/caddy/Caddyfile
$TLS_FQDN {
    root * /syncer/library
    file_server
    tls /etc/caddycerts/cert.pem /etc/caddycerts/key.pem
}
EOF
    else
        cat << EOF > /etc/caddy/Caddyfile
$TLS_FQDN {
    root * /syncer/library
    file_server
}
EOF 
    fi
fi

echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Starting caddy..."
/usr/sbin/caddy start -config /etc/caddy/Caddyfile

echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Starting cron..."
exec "$@"