#!/bin/sh

set -e

# insert optional random delay
if [ x$1 == x"delay" ]; then
    echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Waiting for random delay..."
    sleep $(( RANDOM % SYNC_DELAY_MAX_SECONDS + 1 ))
fi

echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Sync sync starts NOW!"
# sync
/usr/bin/rsync -e "ssh -l syncer -p $SYNC_PORT -i /syncer/.ssh/id_syncer -o StrictHostKeyChecking=no" -av --exclude '*.json' $SYNC_PEER:/ /syncer/library

# generate content library manifest
echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Generating content library manifest..."
/usr/bin/python3 /syncer/update_library_manifests.py -n 'Library' -p /syncer/library/

echo -e "[$(date +"%Y/%m/%d-%H:%M:%S")] Sync tasks complete!"