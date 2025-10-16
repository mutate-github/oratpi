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

THRESHOLD=$($BASEDIR/iniget.sh $CONFIG locks threshold)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "HOST="$HOST
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
    LOGF=$LOGDIR/mon_lock_${HOST}_${DB}.log
    $WRTPI $HOST $DB lock  > $LOGF
    CUR_VAL=$(egrep "Waiter" $LOGF | awk '{print $NF}' | sort -n | awk -v lim=$THRESHOLD '{if($NF+0>=lim) {print $NF}}' | head -1)
    if [ -n "$CUR_VAL" ]; then
       cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $HOST $DB "Locks warning: (current: $CUR_VAL min, threshold: $THRESHOLD min)"
       rm $LOGF 
    fi
  done # DB
done # HOST

