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
WRTPI="$BASEDIR/rtpi"
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)
RCNTLIM=$($BASEDIR/iniget.sh $CONFIG threshold resumable)
echo "RCNTLIM: "$RCNTLIM

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
    RCNT=$($WRTPI $HOST $DB resumable | awk '/^RESUMABLE_COUNT/{f=1;getline;getline}f')

    if [[ -n "$RCNTLIM" && "$RCNT" -gt "$RCNTLIM" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "RESUMABLE_COUNT sessions limit warning: (current: $RCNT, limit: $RCNTLIM)"
    fi
  done # DB
done # HOST

