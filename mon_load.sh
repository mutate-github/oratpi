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
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
limPER=$($BASEDIR/iniget.sh $CONFIG threshold osload)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST: "$HOST
#-- skip for host
  skip_outer_loop=0
  for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
     SCRIPTS=$(cut -d':' -f3- <<< $EXCL)
     if [[ $(awk -F: '{print $1}' <<< $EXCL) = "$HOST" ]] && (grep -q "$ME" <<< "$SCRIPTS"); then
       echo "Find EXCLUDE HOST: $HOST   in   EXCL: $EXCL"
       echo "Find EXCLUDE SCRIPT: $ME   in   SCRIPTS: $SCRIPTS" ; skip_outer_loop=1; break
     fi
  done
  if [ "$skip_outer_loop" -eq 1 ]; then echo "SKIP and continue outher loop!"; continue; fi
#-- end skip for host

  LOGF=$LOGDIR/mon_swap_${HOST}.log
  LOGF_HEAD=$LOGDIR/mon_swap_${HOST}_head.log
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
   Linux)
          $SSHCMD "$HOST" "cat /proc/loadavg | awk '{printf (\"%3.0f\", \$2)}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   AIX)   $SSHCMD "$HOST" "lparstat 6 1 | tail -1 | awk '{printf (\"%3.0f\", \$7)}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   SunOS) $SSHCMD "$HOST" "uptime | awk '{printf (\"%3.0f\", \$(NF-1))}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
  esac
  if [ -s $LOGF ]; then
    if [[ "$PCT" -ge "$limPER" ]]; then
      echo -e "Fired: "$0"\n" > $LOGF_HEAD
      cat $LOGF_HEAD $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST NULL "Overall OS Load % warning: (current: ${PCT} %, threshold: ${limPER} %)"
      rm $LOGF_HEAD
    fi
    rm $LOGF
  fi
done


