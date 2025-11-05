#!/bin/bash
set -f

# Usage: $0 LOCKFILE PID_PARENT_SCRIPT

LOCKFILE="$1"
SCRIPTPID="$2"

if [ -f $LOCKFILE ]; then
    PID=$(cat $LOCKFILE)
    if ps -p $PID > /dev/null 2>&1; then
        echo "Script with lockfile: $LOCKFILE is already running with PID: $PID"
        exit 1
    else
	echo "Removing stale lock file: $LOCKFILE"
        rm -f $LOCKFILE
    fi
fi
echo "$SCRIPTPID" > $LOCKFILE

