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
ORATOP_DBTM_X=$($BASEDIR/iniget.sh $CONFIG threshold ORATOP_DBTM_X)
echo "ORATOP_IORL_LIMIT: "$ORATOP_IORL_LIMIT
echo "ORATOP_DBTM_X: "$ORATOP_DBTM_X

echo "SCRIPTS_EXCLUDE: "$SCRIPTS_EXCLUDE
echo "ME: "$ME

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
#---
#--- for NOMAD
    [[ "$DB" == "aisutf" || "$DB" == unit* || "$DB" == "msfo" ]] && WRTPI="$BASEDIR/rtpi2"
#---
    LOGF="$LOGDIR/${SCRIPT_NAME}_${HOST}_${DB}_out.txt"
# for oratop h
#1                     2      3    4    5    6      7      8     9    10    11    12    13    14    15     16       17       18     19      20     21         22      23      24     25     26   27   28   29
#BEGIN_TIME        HCPUB CPUUPS LOAD DCTR DWTR   SPFR   TPGA   SCT   AAS   AST ASCPU  ASIO  ASWA  ASPQ   UTPS     UCPS     SSRT IOMBPS    IOPS   IORL       LOGR    PHYR    PHYW   TEMP   DBTM   IN  CON NCPU
#22/10/25-13:21:54     0      0    0   87   12      9    699   119     0     1     1     0     0     0      0        1       14      0       5      0        587       0       0      0      0    1    0    8

    $WRTPI $HOST $DB oratop h | awk  '/^BEGIN_TIME |^[0-9]/' > $LOGF

    NUM_COL_IORL=$(awk  '/BEGIN_TIME/{for(i=1;i<=NF;++i) if ($i=="IORL") print i }' $LOGF)
    echo -n "NUM_COL_IORL: "$NUM_COL_IORL
    sed '1,2d' $LOGF | sed '$d' > ${LOGF}.cut.log  # cut 1,2 (heap) and last line - bad statistics
    GLINES="31"

    cat ${LOGF}.cut.log | tail -$GLINES | awk -v IORL="$NUM_COL_IORL" '{ iorltotal+=$IORL; lin+=1 } END {printf " iorltotal: %.0f", iorltotal; printf " lin: %.0f", lin; (lin>0 ? iorlav=iorltotal/lin : 0);  printf " iorlav: %.2f", iorlav }'
    VAL_IORL=$(cat ${LOGF}.cut.log | tail -$GLINES | awk -v IORL="$NUM_COL_IORL" '{ iorltotal+=$IORL; lin+=1 } END {(lin>0 ? iorlav=iorltotal/lin : 0);  printf "%.0f", iorlav }')
    echo -n  "  VAL_IORL: "$VAL_IORL
    if [ "$VAL_IORL" -gt "$ORATOP_IORL_LIMIT" ]; then
      cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "IORL Warning in last 30 min, current: $VAL_IORL, threshold: $ORATOP_IORL_LIMIT"
    fi

    NUM_COL_DBTM=$(awk '/BEGIN_TIME/{for(i=1;i<=NF;++i) if ($i=="DBTM") print i }' $LOGF)
    echo ""
    echo -n "NUM_COL_DBTM: "$NUM_COL_DBTM
    tail -$GLINES ${LOGF}.cut.log > ${LOGF}.cut.log.tmp && mv ${LOGF}.cut.log.tmp ${LOGF}.cut.log
    HALF_LINES=$(( $(tail -$GLINES ${LOGF}.cut.log | wc -l) / 2 ))
    VAL_DBTMAV=$(tail -$GLINES ${LOGF}.cut.log | awk -v DBTM="$NUM_COL_DBTM" '{ dbtm+=$DBTM; lin+=1 } END {(lin>0 ? dbtmav=dbtm/lin : 0); printf "%.0f", dbtmav}')
    VAL_1HALFAV=$(head -$HALF_LINES ${LOGF}.cut.log | awk -v DBTM="$NUM_COL_DBTM" '{ dbtm+=$DBTM; lin+=1 } END {(lin>0 ? dbtmav=dbtm/lin : 0); printf "%.0f", dbtmav}')
    VAL_2HALFAV=$(tail -$HALF_LINES ${LOGF}.cut.log | awk -v DBTM="$NUM_COL_DBTM" '{ dbtm+=$DBTM; lin+=1 } END {(lin>0 ? dbtmav=dbtm/lin : 0); printf "%.0f", dbtmav}')
    echo -n "  VAL_DBTMAV: "$VAL_DBTMAV
    echo -n "  VAL_1HALFAV: "$VAL_1HALFAV
    echo -n "  VAL_2HALFAV: "$VAL_2HALFAV
    X_1HALFAV=$(( $VAL_1HALFAV * "$ORATOP_DBTM_X" ))
    echo -n "  X_1HALFAV: "$X_1HALFAV

    DIFF_2HALF_1HALF=$(( $VAL_2HALFAV - VAL_1HALFAV ))
    echo -n "  DIFF_2HALF_1HALF: "$DIFF_2HALF_1HALF
    echo -n "  for triggering must VAL_2HALFAV -gt VAL_1HALFAV * $ORATOP_DBTM_X and DIFF_2HALF_1HALF must be bigger than VAL_DBTMAV and VAL_1HALFAV -gt 60"
    echo ""
    if [[ "$VAL_2HALFAV" -gt "$X_1HALFAV" && "$DIFF_2HALF_1HALF" -gt "$VAL_DBTMAV" && "$VAL_1HALFAV" -gt 60 ]]; then
      cat $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "DBTM Warning in last 30 min: last 15min: $VAL_2HALFAV * $ORATOP_DBTM_X are bigger than first 15min: $VAL_1HALFAV"
    fi
  done
done

