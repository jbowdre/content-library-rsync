#!/bin/sh
set -e

# create user
if [ ! $(id syncer) ]; then
    adduser -u ${SYNCER_UID:-31337} -h /home/syncer -D -s /bin/sh syncer
fi

# set ssh config permissions
echo "$SYNC_CMD $(cat /home/syncer/.ssh/id_syncer.pub)" > /home/syncer/.ssh/authorized_keys
chown -R syncer:syncer /home/syncer \
&& chmod 700 /home/syncer/.ssh \
&& chmod 600 /home/syncer/.ssh/authorized_keys
if [ $(getent shadow syncer | awk 'BEGIN { FS = ":" } ; { print $2 }') == '!' ]; then
    passwd -u syncer
fi

# generate host keys
if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_rsa_key -N '' -t rsa
fi
if [ ! -f "/etc/ssh/ssh_host_dsa_key" ]; then
    ssh-keygen -f /etc/ssh/ssh_host_dsa_key -N '' -t dsa
fi
if [ ! -d "/var/run/sshd" ]; then
    mkdir -p /var/run/sshd
fi

sed -i "s/^#PasswordAuthentication yes/PasswordAuthentication no/g" /etc/ssh/sshd_config

echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Starting sshd..."
exec "$@"
