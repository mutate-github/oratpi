#!/bin/bash
set -f

CLIENT="$1"
HOST="$2"
FILEPATH=$0
BASEDIR=${FILEPATH%/*}
SCRIPT_NAME=${FILEPATH##*/}
LOCKFILE="/tmp/${SCRIPT_NAME}_${CLIENT}.pid"
trap 'rm -f $LOCKFILE' EXIT TERM INT
echo "Starting $0 at: "$(date +%d/%m/%y-%H:%M:%S)
if ! $BASEDIR/checkalrun.sh $LOCKFILE $$; then exit 1; fi

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
[[ -z "$HOST" ]] && HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host) || HOSTS="$HOST"
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=$(<$SET_ENV_F)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

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
       if [[ "$HOST_" = "$HOST" || "$HOST_" = % ]] && [[ "$DB_" = "$DB" || "$DB_" = % ]]  && [[ "$SCRIPTS_" == *"$SCRIPT_NAME"* || "$SCRIPTS_" == *%* ]]; then
         echo "Find EXCLUDE HOST:   $HOST in   EXCL: $EXCL"
         echo "Find EXCLUDE DB:     $DB   in   EXCL: $EXCL"
         echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop_db=1; break
       fi
    done
    if [ "$skip_outer_loop_db" -eq 1 ]; then echo "SKIP and continue outher loop db!"; continue; fi
#--- end skip for db
   
    ALLRL=$($WRTPI $HOST $DB resource_limit | awk '/RESOURCE_NAME/{f=1;getline;getline}f')
    echo $ALLRL | xargs -n5 echo | while read INST_ID RESOURCE_NAME CURRENT_UTILIZATION LIMIT_VALUE PERCENT; do
#   INST_ID RESOURCE_NAME                            CURRENT_UTILIZATION LIMIT_VALUE     PERCENT
#---------- ---------------------------------------- ------------------- --------------- -------
#         1 processes                                                 36       5500            0
#         1 sessions                                                  35       6055            0

    if [[ -n "$RESOURCE_NAME" ]]; then
      PERLIM=$($BASEDIR/iniget.sh $CONFIG threshold $RESOURCE_NAME)
      printf "%-15s %-24s %-8s %-4s %-8s %-4s \n" "RESOURCE_NAME:" "$RESOURCE_NAME" "PERLIM:" "$PERLIM" "PERCENT:" "$PERCENT"

      if [[ -n "$PERLIM" && "$PERCENT" -gt "$PERLIM" ]]; then
        echo "" | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $DB "$RESOURCE_NAME limit % warning: (current: $CURRENT_UTILIZATION, limit: $LIMIT_VALUE, threshold: $PERLIM % , now: $PERCENT %)"
      fi
    fi
    done
  done # DB
done # HOST


