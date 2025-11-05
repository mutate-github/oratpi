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
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
AAS_CONCUR_LIMIT=$($BASEDIR/iniget.sh $CONFIG threshold AAS_CONCUR_LIMIT)
AAS_COMMIT_LIMIT=$($BASEDIR/iniget.sh $CONFIG threshold AAS_COMMIT_LIMIT)
echo "AAS_CONCUR_LIMIT: "$AAS_CONCUR_LIMIT
echo "AAS_COMMIT_LIMIT: "$AAS_COMMIT_LIMIT

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
#---
#--- for NOMAD
    [[ "$DB" == "aisutf" || "$DB" == unit* || "$DB" == "msfo" ]] && WRTPI="$BASEDIR/rtpi2"
#--- 
    LOGF="$LOGDIR/${SCRIPT_NAME}_${HOST}_${DB}_out.txt"
#$ ash uchart
#1                      2        3        4        5        6        7        8        9       10       11       12       13       14       15       16   18
#BEGIN_TIME           AAS      CPU     BCPU   SHEDUL      UIO      SIO   CONCUR     APPL   COMMIT   CONFIG    ADMIN      NET    QUEUE    CLUST    OTHER   IN
#--------------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- -------- ----
#22/10/25-10:31      5.62     4.38     0.00     0.00     1.10     0.02     0.00     0.00     0.12     0.00     0.00     0.00     0.00     0.00     0.00    1

    $WRTPI $HOST $DB ash uchart | awk  '/^BEGIN_TIME |^[0-9]/' > $LOGF

    GLINES="31"

    NUM_COL_AAS=$(awk  '/BEGIN_TIME/{for(i=1;i<=NF;++i) if ($i=="AAS") print i }' $LOGF)
    NUM_COL_CONCUR=$(awk  '/BEGIN_TIME/{for(i=1;i<=NF;++i) if ($i=="CONCUR") print i }' $LOGF)
#    echo "NUM_COL_AAS: "$NUM_COL_AAS
#    echo "NUM_COL_CONCUR: "$NUM_COL_CONCUR

    awk '/^[0-9][0-9]\/.*$/' $LOGF | tail -$GLINES | awk -v AAS="$NUM_COL_AAS" -v CONCUR="$NUM_COL_CONCUR" \
        '{ as+=$AAS; co+=$CONCUR; lin+=1 } END {avas=(lin>0 ? as/lin : 0); avco=(lin>0 ? co/lin : 0); printf " as: %.2f", as; printf " co: %.2f", co;  printf " lin: %.0f", lin;  printf " avas: %.2f", avas; printf " avco: %.2f ", avco; perco=(avas>0 ? avco/avas*100 : 0);  printf " perconcur: %.2f", perco }'
    VALUE=$(awk '/^[0-9][0-9]\/.*$/' $LOGF | tail -$GLINES | awk -v AAS="$NUM_COL_AAS" -v CONCUR="$NUM_COL_CONCUR" '{ as+=$AAS; co+=$CONCUR; lin+=1 } END {avas=(lin>0 ? as/lin : 0); avco=(lin>0 ? co/lin : 0); if (avco>1) {perco=(avas>0 ? avco/avas*100 : 0); printf "%.0f", perco} else print 0; }')
    echo -e "  VALUE: "$VALUE
    if [ "$VALUE" -gt "$AAS_CONCUR_LIMIT" ]; then
      cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $DB "CONCUR % Warning in last 30 min, current: $VALUE, threshold: $AAS_CONCUR_LIMIT"
    fi

############

    NUM_COL_COMMIT=$(awk  '/BEGIN_TIME/{for(i=1;i<=NF;++i) if ($i=="COMMIT") print i }' $LOGF)

    awk '/^[0-9][0-9]\/.*$/' $LOGF | tail -$GLINES | awk -v AAS="$NUM_COL_AAS" -v COMMIT="$NUM_COL_COMMIT" \
        '{ as+=$AAS; co+=$COMMIT; lin+=1 } END {avas=(lin>0 ? as/lin : 0); avco=(lin>0 ? co/lin : 0); printf " as: %.2f", as; printf " co: %.2f", co;  printf " lin: %.0f", lin;  printf " avas: %.2f", avas; printf " avco: %.2f ", avco; perco=(avas>0 ? avco/avas*100 : 0);  printf " percommit: %.2f", perco }'
    VALUE=$(awk '/^[0-9][0-9]\/.*$/' $LOGF | tail -$GLINES | awk -v AAS="$NUM_COL_AAS" -v COMMIT="$NUM_COL_COMMIT" '{ as+=$AAS; co+=$COMMIT; lin+=1 } END {avas=(lin>0 ? as/lin : 0); avco=(lin>0 ? co/lin : 0); if (avco>1) {perco=(avas>0 ? avco/avas*100 : 0); printf "%.0f", perco} else print 0; }')
    echo -e "  VALUE: "$VALUE
    if [ "$VALUE" -gt "$AAS_COMMIT_LIMIT" ]; then
      cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST $DB "COMMIT % Warning in last 30 min, current: $VALUE, threshold: $AAS_COMMIT_LIMIT"
    fi
  done
done

