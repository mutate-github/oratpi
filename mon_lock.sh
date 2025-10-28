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
THRESHOLD=$($BASEDIR/iniget.sh $CONFIG threshold enq_locks)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)
echo "THRESHOLD: "$THRESHOLD

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
#  $BASEDIR/test_ssh.sh $CLIENT $HOST
#  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
#--- skip for host:db:script1:script2
    skip_outer_loop_db=0
    for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
       HOST_=$(awk -F: '{print $1}' <<< $EXCL)
       DB_=$(awk -F: '{print $2}' <<< $EXCL)
       SCRIPTS_=$(cut -d':' -f3- <<< $EXCL)
       if [[ "$HOST_" = "$HOST" || "$HOST_" = % ]] && [[ "$DB_" = "$DB" || "$DB_" = % ]]  && [[ "$SCRIPTS_" == *"$ME"* || "$SCRIPTS_" == *%* ]]; then
         echo "Find EXCLUDE HOST:   $HOST in   EXCL: $EXCL"
         echo "Find EXCLUDE DB:     $DB   in   EXCL: $EXCL"
         echo "Find EXCLUDE SCRIPT: $ME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop_db=1; break
       fi
    done
    if [ "$skip_outer_loop_db" -eq 1 ]; then echo "SKIP and continue outher loop db!"; continue; fi
#--- end skip for db
    
    LOGF=$LOGDIR/mon_lock_${HOST}_${DB}.log
    $WRTPI $HOST $DB lock  > $LOGF
    CUR_VAL=$(egrep "Waiter" $LOGF | awk '{print $NF}' | sort -n | awk -v lim=$THRESHOLD '{if($NF+0>=lim) {print $NF}}' | head -1)
    if [ -n "$CUR_VAL" ]; then
       cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "Locks warning: (current: $CUR_VAL min, threshold: $THRESHOLD min)"
       rm $LOGF 
    fi
  done # DB
done # HOST

