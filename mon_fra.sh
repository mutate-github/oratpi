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
limPER=$($BASEDIR/iniget.sh $CONFIG threshold FRA)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST="$HOST
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  DBS=$($BASEDIR/iniget.sh $CONFIG $HOST db)
  for DB in $(xargs -n1 echo <<< "$DBS"); do
    echo "DB="$DB
    LOGF=$LOGDIR/mon_fra_${HOST}_${DB}.log
    LOGF_HEAD=$LOGDIR/mon_fra_${HOST}_${DB}_head.log
    LOGF_TRG=$LOGDIR/mon_fra_${HOST}_${DB}_trg.log
    $WRTPI $HOST $DB fra | awk '/PCT_FULL/{ getline; getline; print $0; }' > $LOGF
    awk -v lim=$limPER '{if($NF+0>lim) {print $0}}' $LOGF >  $LOGF_TRG

    if [ -s $LOGF_TRG ]; then
      echo "Fired: "$0"\n" > $LOGF_HEAD
      CUR_VAL=$((tail -1 | awk '{print $NF}')<"$LOGF_TRG")
      cat $LOGF_HEAD $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "FRA % usage warning (current: $CUR_VAL %, threshold: $limPER %)"
      rm $LOGF_HEAD
    fi
    rm $LOGF $LOGF_TRG
  done # DB
done # HOST

