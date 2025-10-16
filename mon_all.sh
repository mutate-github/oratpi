#!/bin/bash

CLIENT="$1"
BASEDIR=`dirname $0`
echo $BASEDIR
# cd $BASEDIR
mkdir -p $BASEDIR/../log
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Using config: ${CONFIG}"

echo "Checking if previous script did finish... "$(date)
echo $0
etime=`ps -eo 'pid,etime,args' | egrep "$0 $CLIENT" | awk '!/grep|00:0[0123]/{print $2}'`
if [[ -n "$etime" ]] && [[ ! "$etime" =~ "00:0[0123]" ]]; then
   echo "Previous script did not finish. "$(date)
   ps -eo 'pid,ppid,lstart,etime,args' | egrep "$0 $CLIENT" | awk '!/grep|00:0[0123]/'
   echo "Cancelling running now, send alert message and exiting ..."
   ps -fu oracle | $BASEDIR/send_msg.sh $CONFIG "Script: " $0 " did not finish, do check for hung previous"
   exit 127
fi

echo ""
echo "START ALL MONITORING *****************************************************************************"$(date)
echo "Monitor: ================================================================================ mon_ping.sh "$(date)
$BASEDIR/mon_ping.sh $CLIENT
echo "Monitor: ================================================================================ mon_ssh.sh "$(date)
$BASEDIR/mon_ssh.sh $CLIENT
echo "Monitor: ================================================================================ mon_db.sh "$(date)
$BASEDIR/mon_db.sh $CLIENT
echo "Monitor: ================================================================================ mon_fs.sh "$(date)
$BASEDIR/mon_fs.sh $CLIENT
echo "Monitor: ================================================================================ mon_disksp.sh "$(date)
$BASEDIR/mon_disksp.sh $CLIENT
echo "Monitor: ================================================================================ mon_swap.sh "$(date)
$BASEDIR/mon_swap.sh $CLIENT
echo "Monitor: ================================================================================ mon_load.sh "$(date)
$BASEDIR/mon_load.sh $CLIENT
echo "Monitor: ================================================================================ mon_alert.sh "$(date)
$BASEDIR/mon_alert.sh $CLIENT
#$BASEDIR/mon_adrcial.sh $CLIENT
echo "Monitor: ================================================================================ mon_fra.sh "$(date)
$BASEDIR/mon_fra.sh $CLIENT
echo "Monitor: ================================================================================ mon_tbs.sh "$(date)
$BASEDIR/mon_tbs.sh $CLIENT
echo "Monitor: ================================================================================ mon_stb.sh "$(date)
$BASEDIR/mon_stb.sh $CLIENT
echo "Monitor: ================================================================================ mon_bck.sh "$(date)
$BASEDIR/mon_bck.sh $CLIENT
echo "Monitor: ================================================================================ mon_db_files.sh "$(date)
$BASEDIR/mon_db_files.sh $CLIENT
echo "Monitor: ================================================================================ mon_reslim.sh "$(date)
$BASEDIR/mon_reslim.sh $CLIENT
echo "Monitor: ================================================================================ mon_resumab.sh "$(date)
$BASEDIR/mon_resumab.sh $CLIENT
echo "Monitor: ================================================================================ mon_pga.sh "$(date)
$BASEDIR/mon_pga.sh $CLIENT
echo "Monitor: ================================================================================ mon_lock.sh "$(date)
$BASEDIR/mon_lock.sh $CLIENT
echo "Monitor: ================================================================================ kill_sniped.sh "$(date)
$BASEDIR/kill_sniped.sh $CLIENT
echo "FINISH ALL MONITORING ****************************************************************************"$(date)



