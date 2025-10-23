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
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)


for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
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
   
    ALLRL=$($WRTPI $HOST $DB resource_limit | awk '/RESOURCE_NAME/{f=1;getline;getline}f')
    echo $ALLRL | xargs -n4 echo | while read RESOURCE_NAME CURRENT_UTILIZATION LIMIT_VALUE PERCENT; do
#RESOURCE_NAME                            CURRENT_UTILIZATION LIMIT_VALUE     PERCENT
#---------------------------------------- ------------------- --------------- -------
#processes                                               1495      15000            9
    PERLIM=$($BASEDIR/iniget.sh $CONFIG threshold $RESOURCE_NAME)

    if [[ -n "$PERLIM" && "$PERCENT" -gt "$PERLIM" ]]; then
      echo "" | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "$RESOURCE_NAME limit % warning: (current: $CURRENT_UTILIZATION, limit: $LIMIT_VALUE, threshold: $PERLIM % , now: $PERCENT %)"
    fi
    done
  done # DB
done # HOST

