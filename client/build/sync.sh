#!/bin/sh

set -e

# initial sync is immediate, cron syncs have a random delay unless $CRON_DELAY==false
if [ $1 == "delay" ]; then
    echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Waiting for random delay..."
    sleep $(( RANDOM % SYNC_DELAY_MAX_SECONDS + 1 ))
    echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Sync starts NOW!"
else 
    echo -e "\n[$(date +"%Y/%m/%d-%H:%M:%S")] Immediate sync starts NOW!"
fi

# sync
echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Rsyncing content..."
/usr/bin/rsync -e "ssh -l syncer -p $SYNC_PORT -i /syncer/.ssh/id_syncer -o StrictHostKeyChecking=no" -av --exclude '*.json' $SYNC_PEER:/ /syncer/library

# generate content library manifest
echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Generating content library manifest..."
/usr/bin/python3 /syncer/update_library_manifests.py -n 'Library' -p /syncer/library/

echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Sync tasks complete!\n"