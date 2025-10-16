#!/bin/bash
set -f

CLIENT="$1"
BASEDIR=$(dirname $0)
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Using config: ${CONFIG}"

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
SCRIPT_NAME=$(basename $0)
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  TRG_FILE="$LOGDIR/${SCRIPT_NAME}_${HOST}.trg"
  ping -w3 -W 10 $HOST
  if [ $? -ne 0 ]; then
    if [ ! -f $TRG_FILE ]; then
      touch $TRG_FILE
      echo "" | $BASEDIR/send_msg.sh $CONFIG $HOST $DB "TRIGGER: PING is NOT responding"
    fi
  else
    if [ -f $TRG_FILE ]; then
      rm -f $TRG_FILE
      echo "" | $BASEDIR/send_msg.sh $CONFIG $HOST $DB "RECOVER: PING responds"
    fi
  fi
done

