#!/bin/bash
set -f

# Usage $0 CLIENT HOST

CLIENT="$1"
HOST="$2"
BASEDIR=$(dirname $0)
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
# echo "Using config: ${CONFIG}"
LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
SCRIPT_NAME=$(basename $0)

# echo "HOST="$HOST
TRG_FILE="$LOGDIR/${SCRIPT_NAME}_${HOST}.trg"
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
$SSHCMD -q $HOST exit
if [ "$?" -eq 0 ]; then
  exit 0
else
  exit 127
fi

