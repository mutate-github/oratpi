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
echo "Starting $0 at: "$(date +%d/%m/%y-%H:%M:%S)
echo "Using config: ${CONFIG}"

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
SCRIPT_NAME=$(basename $0)
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
#-- skip for host
  skip_outer_loop=0
  for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
     SCRIPTS=$(cut -d':' -f3- <<< $EXCL)
     if [[ $(awk -F: '{print $1}' <<< $EXCL) = "$HOST" ]] && (grep -q "$ME" <<< "$SCRIPTS"); then
       echo "Find EXCLUDE HOST: $HOST   in   EXCL: $EXCL"
       echo "Find EXCLUDE SCRIPT: $ME   in   SCRIPTS: $SCRIPTS" ; skip_outer_loop=1; break
     fi
  done
  if [ "$skip_outer_loop" -eq 1 ]; then echo "SKIP and continue outher loop!"; continue; fi
#-- end skip for host

  TRG_FILE="$LOGDIR/${SCRIPT_NAME}_${HOST}.trg"
  ping -w3 -W 10 $HOST
  if [ $? -ne 0 ]; then
    if [ ! -f $TRG_FILE ]; then
      touch $TRG_FILE
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "TRIGGER: PING is NOT responding"
    fi
  else
    if [ -f $TRG_FILE ]; then
      rm -f $TRG_FILE
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "RECOVER: PING responds"
    fi
  fi
done

