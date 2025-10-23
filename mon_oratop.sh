#!/bin/bash
set -f

CLIENT="$1"
HOST="$2"
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
WRTPI="$BASEDIR/rtpi"
[[ -z "$HOST" ]] && HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host) || HOSTS="$HOST"
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)
ORATOP_IORL_LIMIT=$($BASEDIR/iniget.sh $CONFIG threshold ORATOP_IORL_LIMIT)

echo "SCRIPTS_EXCLUDE: "$SCRIPTS_EXCLUDE
echo "ME: "$ME

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
#---
#--- for NOMAD
    [[ "$DB" == "aisutf" || "$DB" == unit* || "$DB" == "msfo" ]] && WRTPI="$BASEDIR/rtpi2"
#---
    LOGF="$LOGDIR/${SCRIPT_NAME}_${HOST}_${DB}_out.txt"
# for oratop h
#1                     2      3    4    5    6      7      8     9    10    11    12    13    14    15     16       17       18     19      20     21         22      23      24     25     26   27   28   29
#BEGIN_TIME        HCPUB CPUUPS LOAD DCTR DWTR   SPFR   TPGA   SCT   AAS   AST ASCPU  ASIO  ASWA  ASPQ   UTPS     UCPS     SSRT IOMBPS    IOPS   IORL       LOGR    PHYR    PHYW   TEMP   DBTM   IN  CON NCPU
#----------------- ----- ------ ---- ---- ---- ------ ------ ----- ----- ----- ----- ----- ----- ----- ------ -------- -------- ------ ------- ------ ---------- ------- ------- ------ ------ ---- ---- ----
#22/10/25-13:21:54     0      0    0   87   12      9    699   119     0     1     1     0     0     0      0        1       14      0       5      0        587       0       0      0      0    1    0    8

    $WRTPI $HOST $DB oratop h | awk  '/^BEGIN_TIME |^[0-9]/' > $LOGF

    NUM_COL_IORL=$(awk  '/BEGIN_TIME/{for(i=1;i<=NF;++i) if ($i=="IORL") print i }' $LOGF)
    echo "NUM_COL_IORL: "$NUM_COL_IORL

    cat $LOGF | tail -31 | awk -v IORL="$NUM_COL_IORL" '{ if ($1 ~ /^[0-9][0-9]\/.*$/) {iorltotal+=$IORL; lin+=1} } END {printf " iorltotal: %.0f", iorltotal; printf " lin: %.0f", lin; (lin>0 ? iorlav=iorltotal/lin : 0);  printf " iorlav: %.2f", iorlav }'
    VALUE=$(cat $LOGF | tail -31 | awk -v IORL="$NUM_COL_IORL" '{ if ($1 ~ /^[0-9][0-9]\/.*$/) {iorltotal+=$IORL; lin+=1} } END {(lin>0 ? iorlav=iorltotal/lin : 0);  printf "%.0f", iorlav }')
    echo -e "\nVALUE: "$VALUE
    if [ "$VALUE" -gt "$ORATOP_IORL_LIMIT" ]; then
      cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "IORL Warning in last 30 min, current: $VALUE, threshold: $ORATOP_IORL_LIMIT"
    fi

  done
done

