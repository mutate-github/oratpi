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
[[ -z "$HOST" ]] && HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host) || HOSTS="$HOST"
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
limPER=$($BASEDIR/iniget.sh $CONFIG threshold DISK_USAGE_LIMIT_PER)
limGB=$($BASEDIR/iniget.sh $CONFIG threshold DISK_USAGE_LIMIT_DB)
SCRIPTS_EXCLUDE=$($BASEDIR/iniget.sh $CONFIG exclude host:db:scripts)

echo "limPER: "$limPER
echo "limGB: "$limGB

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  echo "++++++++++"
  echo "HOST: "$HOST
#-- skip for host
  skip_outer_loop=0
  for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
     SCRIPTS=$(cut -d':' -f3- <<< $EXCL)
     if [[ $(awk -F: '{print $1}' <<< $EXCL) = "$HOST" ]] && (grep -q "$SCRIPT_NAME" <<< "$SCRIPTS"); then
       echo "Find EXCLUDE HOST: $HOST   in   EXCL: $EXCL"
       echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS: $SCRIPTS" ; skip_outer_loop=1; break
     fi
  done
  if [ "$skip_outer_loop" -eq 1 ]; then echo "SKIP and continue outher loop!"; continue; fi
#-- end skip for host

  LOGF=$LOGDIR/mon_diskspace_${HOST}.log
  LOGF_HEAD=$LOGDIR/mon_diskspace_${HOST}_head.log
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
   Linux)
#          $SSHCMD "$HOST" "ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1; echo ""; df -kP -x squashfs" > $LOGF
          $SSHCMD "$HOST" "[[ -s /sbin/ifconfig ]]; if [ "\$?" -eq 0 ]; then /sbin/ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1; else ip a | awk '/inet .*brd/{print \$2}' | grep -v 127.0.0.1 ; fi; echo ""; df -kP -x squashfs" > $LOGF
          PCT_=$(cat $LOGF | grep -v "/mnt" | awk '/\/.*/{print $5" "int($4/1024/1024)}' | sed -e 's/%//' | sort -rn | head -1)
          PCT=$(echo "$PCT_" | cut -d " " -f 1)
          FS_=$(echo $PCT_ | cut -d " " -f 2)
          ;;
   AIX)   $SSHCMD "$HOST" "/usr/sbin/ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1; echo ""; df -k" > $LOGF
#          cat $LOGF
          PCT_=$(cat $LOGF | egrep -v "-" | awk '/\/.*/{print $4" "int($3/1024/1024)}' | sed -e 's/%//' | sort -rn | head -1)
          PCT=$(echo "$PCT_" | cut -d " " -f 1)
          FS_=$(echo $PCT_ | cut -d " " -f 2)
          ;;
   SunOS)
          $SSHCMD "$HOST" "[[ -s /usr/sbin/ifconfig ]]; if [ "\$?" -eq 0 ]; then /usr/sbin/ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1 | grep -v 0.0.0.0; fi; echo ""; df -k" > $LOGF
          PCT_=$(cat $LOGF | grep -v "/mnt" | awk '/\/.*/{print $5" "int($4/1024/1024)}' | sed -e 's/%//' | sort -rn | head -1)
          PCT=$(echo "$PCT_" | cut -d " " -f 1)
          FS_=$(echo $PCT_ | cut -d " " -f 2)
          ;;
  esac
  if [ -s $LOGF ]; then
    if [ "$PCT" -gt "$limPER" -a "$FS_" -lt "$limGB" ]; then
      echo -e "Fired: "$0"\n" > $LOGF_HEAD
      cat $LOGF_HEAD $LOGF | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST NULL "DISKSPACE usage warning: (current: ${PCT} %, threshold: ${limPER} % and below ${limGB} Gb)"
      rm $LOGF_HEAD
    fi
    rm $LOGF
  fi
done

