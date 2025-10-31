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
limPER=$($BASEDIR/iniget.sh $CONFIG threshold swap)
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)
ME=$(basename $0)

echo "limPER: "$limPER

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST: "$HOST
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
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
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
   Linux)
          $SSHCMD "$HOST" "free | grep 'Swap' | awk '{t = \$2+1; u = \$3; printf (\"%3.0f\", u/(t/100))}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   AIX)   $SSHCMD "$HOST" "lsps -s | tail +2  | cut -d% -f1 | awk '{printf \$2}'" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
   SunOS) # $SSHCMD "$HOST" "swap -s | awk '{ used = \$9; available = \$11; total = used + available; printf \"%.0f\n\", (used / total) * 100 }'" > $LOGF
          $SSHCMD "$HOST" "used=\$(swap -s | awk '{print \$9}' | tr -d 'k'); avail=\$(swap -s | awk '{print \$11}' | tr -d 'k'); total=\$((used + avail)); percent=\$(( used * 100 / total )); echo -n \$percent" > $LOGF
          PCT=$(head -1 $LOGF)
          ;;
  esac
  echo "PCT: "$PCT
  if [ -s $LOGF ]; then
    if [ "$PCT" -ge "$limPER" ]; then
      echo -e "Fired: "$0"\n" > $LOGF_HEAD
      cat $LOGF_HEAD $LOGF | $BASEDIR/send_msg.sh $CONFIG $0 $HOST NULL "Swap % usage warning: (current: ${PCT} %, threshold: ${limPER} %)"
      rm $LOGF_HEAD
    fi
    rm $LOGF
  fi
done


