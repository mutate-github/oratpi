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
  SSHUSER=$($BASEDIR/iniget.sh $CONFIG $HOST sshuser)
  SUDO=$($BASEDIR/iniget.sh $CONFIG $HOST sudo)

#-- skip for host
  skip_outer_loop=0
  for EXCL in $(xargs -n1 echo <<< $SCRIPTS_EXCLUDE); do
     HOST_=$(awk -F: '{print $1}' <<< $EXCL)
     SCRIPTS_=$(cut -d':' -f3- <<< $EXCL)
     if [[ "$HOST_" = "$HOST" || "$HOST_" = %  ]] && [[ "$SCRIPTS_" == *"$SCRIPT_NAME"* || "$SCRIPTS_" == *%* ]]; then
       echo "Find EXCLUDE HOST: $HOST   in   EXCL: $EXCL"
       echo "Find EXCLUDE SCRIPT: $SCRIPT_NAME   in   SCRIPTS_: $SCRIPTS_" ; skip_outer_loop=1; break
     fi
  done
  if [ "$skip_outer_loop" -eq 1 ]; then echo "SKIP and continue outher loop!"; continue; fi
#-- end skip for host

  LOGF=$LOGDIR/mon_diskspace_${HOST}.log
  LOGF2=$LOGDIR/mon_diskspace_${HOST}_above_limit.log
  $BASEDIR/test_ssh.sh $CLIENT $HOST
  if [ "$?" -ne 0 ]; then echo "test_ssh.sh not return 0, continue"; continue; fi
  OS=$($SSHCMD $HOST "uname")
  case "$OS" in
   Linux) # $SSHCMD $SSHUSER $HOST "$SUDO ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1; echo ""; df -kP -x squashfs" > $LOGF
          $SSHCMD $SSHUSER $HOST "$SUDO bash <<-'EOF'
#	  [[ -s /sbin/ifconfig ]] && /sbin/ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1; else ip a | awk '/inet .*brd/{print \$2}' | grep -v 127.0.0.1
	  df -kP -x squashfs
EOF
" > $LOGF
          ;;
   AIX)   $SSHCMD $SSHUSER $HOST "$SUDO bash <<-'EOF'
#	  [[ -s /usr/sbin/ifconfig ]] && /usr/sbin/ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1
	  df -kP
EOF
" > $LOGF
          ;;
   SunOS) $SSHCMD $SSHUSER $HOST "$SUDO bash <<-'EOF'
#	  [[ -s /usr/sbin/ifconfig ]] && /usr/sbin/ifconfig -a | awk '/inet .*ask/{print \$2}' | grep -v 127.0.0.1 | grep -v 0.0.0.0 
	  df -k | awk '{if (NF==1) {getline next_line; print \$0, next_line} else print \$0}'
EOF
" > $LOGF
          ;;
  esac
  awk -v limPER="$limPER" -v limGB="$limGB" 'NR>1 && $5 ~ /%$/ && $5+0 > limPER && $4 < limGB*1024*1024 {printf "%s %d %s %s\n", $5, $4, $1, $NF}' $LOGF > $LOGF2
  if [ -s $LOGF2 ]; then
     cat $LOGF2 | $BASEDIR/send_msg.sh $CONFIG $SCRIPT_NAME $HOST NULL "DISKSPACE usage warning: (threshold: ${limPER} % and below ${limGB} Gb)"
  fi
  rm -f $LOGF $LOGF2
done

