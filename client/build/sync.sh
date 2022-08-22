#!/bin/sh

set -e

# insert optional random delay
if [ x$1 == x"delay" ]; then
    echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Waiting for random delay..."
    sleep $(( RANDOM % ${SYNC_DELAY_MAX_SECONDS:-21600} + 1 ))
fi

echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Sync sync starts NOW!"
# sync
/usr/bin/rsync --progress --bwlimit=${SYNC_MAX_BW:-0} -e "ssh -l syncer -p ${SYNC_PORT:-2222} -i /syncer/.ssh/id_syncer -o StrictHostKeyChecking=no" -avh --stats --exclude '*.json' --exclude '.vSphere-HA' $SYNC_PEER:/ /syncer/library --delete || [ $? -eq 23 ] && true

# handle removed files / remove directories
grep '"files": \[\]' /syncer/library/*/item.json -l | xargs rm -f $1
find /syncer/library -type d -empty -delete

# generate content library manifest
echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Generating content library manifest..."
/usr/bin/python3 /syncer/update_library_manifests.py -n "${LIBRARY_NAME:-Library}" -p /syncer/library/

echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Sync tasks complete!"
