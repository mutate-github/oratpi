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
WRTPI="$BASEDIR/rtpi"
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "HOST="$HOST
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
    ALLRL=$($WRTPI $HOST $DB resource_limit | awk '/RESOURCE_NAME/{f=1;getline;getline}f')
    echo $ALLRL | xargs -n4 echo | while read RESOURCE_NAME CURRENT_UTILIZATION LIMIT_VALUE PERCENT; do
#RESOURCE_NAME                            CURRENT_UTILIZATION LIMIT_VALUE     PERCENT
#---------------------------------------- ------------------- --------------- -------
#processes                                               1495      15000            9
    PERLIM=$($BASEDIR/iniget.sh $CONFIG resource_limit $RESOURCE_NAME)

    if [[ -n "$PERLIM" && "$PERCENT" -gt "$PERLIM" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $HOST $DB "$RESOURCE_NAME limit warning: (current: $CURRENT_UTILIZATION, limit: $LIMIT_VALUE, threshold: $PERLIM % , now: $PERCENT %)"
    fi
    done
  done # DB
done # HOST

