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
SCRIPT_NAME=$(basename $0)
WRTPI="$BASEDIR/rtpi"
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
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

    LOGF=$LOGDIR/mon_db_${HOST}_${DB}.log
    $WRTPI $HOST $DB db | sed -n '/V$INSTANCE:/,/V$DATABASE:/p' | egrep -v '\----|V\$DATABASE:' | sed '/^$/d' > $LOGF

    LOGF_DB_DIFF=$LOGDIR/mon_db_${HOST}_${DB}_db_diff.log
    LOGF_DB_OLD=$LOGDIR/mon_db_${HOST}_${DB}_db_old.log
    touch $LOGF_DB_OLD
    LOGF_DB=$LOGDIR/mon_db_${HOST}_${DB}_db.log
    cat $LOGF | sed -n '1,3p' > $LOGF_DB
    diff $LOGF_DB_OLD $LOGF_DB > $LOGF_DB_DIFF

    if [ -s $LOGF_DB_DIFF ]; then 
        cat $LOGF_DB_DIFF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "DB status has been changed:"
    fi
    cp $LOGF_DB $LOGF_DB_OLD
    rm $LOGF_DB_DIFF $LOGF_DB
  done
done

