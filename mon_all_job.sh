#!/bin/bash

if [ -f ~/.keychain/${HOSTNAME}-sh ]; then source ~/.keychain/${HOSTNAME}-sh ; fi

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


start_job_with_timing()
{
(
    local script="$1"
    local logdir="$BASEDIR/../log"
    
    # Формируем имя файла с номером месяца (например: mon_ping.sh_2023_month12.log)
    local current_month=$(date +%Y_month%m)
    local logfile="${logdir}/${script}_${current_month}.log"
    
    START=$(date +%s)
    
    # Запуск скрипта с записью в недельный лог
    $BASEDIR/${script} $CLIENT >> "$logfile" 2>&1
    
    END=$(date +%s)
    DURATION=$((END - START))
    
    printf "%-15s Duration: %3d s %-10s %-20s \n" "${script}" "$DURATION" " Finish_time: " "$(date +%d/%m/%Y-%H:%M:%S)"
    
    # Очистка старых логов (старше 32 дней)
    # find "$logdir" -name "${script}*.log" -type f -mtime +32 -delete >/dev/null 2>&1 &
    find "$logdir" -name "${script}*.log" -type f -mtime +32 -exec rm {} \; >/dev/null 2>&1 &
) 
}


echo ""
echo "START ALL MONITORING ***************************************************************************** "$(date)
start_job_with_timing mon_ping.sh &
start_job_with_timing mon_ssh.sh &
start_job_with_timing mon_db.sh &
start_job_with_timing mon_tnslsnr.sh &
start_job_with_timing mon_url.sh &
start_job_with_timing mon_port.sh &
start_job_with_timing mon_fs.sh &
start_job_with_timing mon_disksp.sh &
start_job_with_timing mon_swap.sh &
start_job_with_timing mon_load.sh &
start_job_with_timing mon_alert.sh &
# start_job_with_timing mon_adrcial.sh &
start_job_with_timing mon_fra.sh &
start_job_with_timing mon_tbs.sh &
start_job_with_timing mon_stb.sh &
start_job_with_timing mon_bck.sh &
start_job_with_timing mon_db_files.sh &
start_job_with_timing mon_reslim.sh &
start_job_with_timing mon_resumab.sh &
start_job_with_timing mon_pga.sh &
start_job_with_timing mon_lock.sh &
start_job_with_timing mon_forlog.sh &
start_job_with_timing mon_aas.sh &
start_job_with_timing mon_oratop.sh &
start_job_with_timing kill_sniped.sh &
wait
echo "FINISH ALL MONITORING **************************************************************************** "$(date)

