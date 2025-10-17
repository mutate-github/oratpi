#!/bin/bash
# monitoring standby oracle Standard edition SE
set -f

CLIENT="$1"
BASEDIR=`dirname $0`
CONFIG="mon.ini"
if [ -n "$CLIENT" ]; then
  shift
  CONFIG=${CONFIG}.${CLIENT}
  if [ ! -s "$BASEDIR/$CONFIG" ]; then echo "Exiting... Config not found: "$CONFIG ; exit 128; fi
fi
echo "Using config: ${CONFIG}  Starting at: "$(date)

# $1 is client name

LOGDIR="$BASEDIR/../log"
if [ ! -d "$LOGDIR" ]; then mkdir -p "$LOGDIR"; fi
ADMINS=`$BASEDIR/iniget.sh $CONFIG admins email`
SSHCMD=$($BASEDIR/iniget.sh $CONFIG others SSHCMD)
SET_ENV_F="$BASEDIR/set_env"
SET_ENV=`cat $SET_ENV_F`
SEQ_GAP=$($BASEDIR/iniget.sh $CONFIG standby seq_gap)
LAG_MINUTES=$($BASEDIR/iniget.sh $CONFIG standby lag_minutes)
REPEAT_MINUTES=$($BASEDIR/iniget.sh $CONFIG mail repeat_minutes)
REPEAT_AT=$($BASEDIR/iniget.sh $CONFIG mail repeat_at)
HOSTS=$($BASEDIR/iniget.sh $CONFIG servers host)

for HOST in $(xargs -n1 echo <<< "$HOSTS"); do
  CFG_STB_SE=`$BASEDIR/iniget.sh $CONFIG standby $HOST`  #aisutf:aisstb
  for CFG_STB_LINE in $(xargs -n1 echo <<< "$CFG_STB_SE"); do
    echo "DEBUG:  CFG_STB_LINE="$CFG_STB_LINE
    DB=$(echo $CFG_STB_LINE | awk -F: '{print $1}')
    HOST_STB=$(echo $CFG_STB_LINE | awk -F: '{print $2}')
    echo "DEBUG:  HOST="$HOST"  DB="$DB"  HOST_STB="$HOST_STB
  
if [ -n "$HOST_STB" ]; then
  VALUE_STB=$(cat << EOF | $SSHCMD $HOST_STB "/bin/bash -s $DB"
#!/bin/bash
sid=\$1
$SET_ENV
export ORACLE_SID=\$sid
  sqlplus -S '/as sysdba' <<- 'END'
  set pagesize 0 feedback off verify off heading off echo off timing off
  select max(fhrba_Seq)-1 from x\$kcvfh;
END
EOF
)
  VALUE_STB=$(echo $VALUE_STB | sed -e 's/^ //')

  VALUE_PRI=$(cat << EOF | $SSHCMD $HOST "/bin/bash -s $DB $VALUE_STB"
#!/bin/bash
sid=\$1
VALUE_STB=\$2
$SET_ENV
export ORACLE_SID=\$sid
  sqlplus -S '/as sysdba' <<- 'END'
  set pagesize 0 feedback off verify off heading off echo off timing off
  col SEQ_GAP format 9999999
  col LAG_MINUTES format 9999999.99
  SELECT 'NULL_DEST', PRIMARY_SEQ, SEQ_GAP_NOW, nvl(round((PR_TIME - (SELECT next_time FROM v\$archived_log where RESETLOGS_CHANGE#=(select RESETLOGS_CHANGE# from v\$database) AND SEQUENCE#=$VALUE_STB AND rownum=1)) * 24 * 60),0) LAG_MINUTES_NOW
  FROM ( SELECT MAX(sequence#) PRIMARY_SEQ, MAX(sequence#) - $VALUE_STB SEQ_GAP_NOW, MAX(next_time) PR_TIME FROM v\$archived_log where RESETLOGS_CHANGE#=(select RESETLOGS_CHANGE# from v\$database));
END
EOF
)
  VALUE_PRI=$(echo $VALUE_PRI | sed -e 's/^ //')
  ALL_VALUES=$VALUE_PRI"  "$VALUE_STB
  echo "DEBUG:  ALL_VALUES: "$ALL_VALUES

    while read DEST_ID PRIMARY_SEQ SEQ_GAP_NOW LAG_MINUTES_NOW VALUE_STB; do
      TRG_FILE_SEQ_GAP=$LOGDIR/mon_stb_${HOST}_${DB}_${HOST_STB}_trgfile_seq_gap.log
      TRG_FILE_LAG_MINUTES=$LOGDIR/mon_stb_${HOST}_${DB}_${HOST_STB}_trgfile_lag_minutes.log

      echo "DEBUG:  SEQ_GAP_NOW: " $SEQ_GAP_NOW"   LAG_MINUTES_NOW: " $LAG_MINUTES_NOW "   PRIMARY_SEQ: "$PRIMARY_SEQ "  VALUE_STB: "$VALUE_STB  
      LAG_MINUTES_NOW=$(awk '{printf "%.0f", $1}' <<< "$LAG_MINUTES_NOW")
      if [[ -s $TRG_FILE_SEQ_GAP ]]; then
        if [[ "$SEQ_GAP_NOW" -lt "$SEQ_GAP" ]]; then
          SEQ_GAP_WAS=$(<$TRG_FILE_SEQ_GAP)
          rm $TRG_FILE_SEQ_GAP
          cat $ALL_VALUES | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "- RECOVER: $(date +%H:%M:%S-%d/%m/%y) was ${SEQ_GAP_WAS}, now ${SEQ_GAP_NOW} archivelogs not applyed to standby: ${HOST_STB} (SEQ_GAP limit = $SEQ_GAP logs)"
          echo "SEQ_GAP recover host: "${HOST} " database: "${DB}
        fi
      else
        if [[ "$SEQ_GAP_NOW" -ge "$SEQ_GAP" ]]; then
          echo "$SEQ_GAP_NOW" > "$TRG_FILE_SEQ_GAP"
          cat $ALL_VALUES | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "- TRIGGER: $(date +%H:%M:%S-%d/%m/%y) now ${SEQ_GAP_NOW} archivelogs not applyed to standby: ${HOST_STB} (SEQ_GAP limit = $SEQ_GAP logs)"
          echo "SEQ_GAP trigger host: "${HOST} " database: "${DB}
        fi
      fi

      if [[ -s $TRG_FILE_LAG_MINUTES ]]; then
        if [[ "$LAG_MINUTES_NOW" -lt "$LAG_MINUTES" ]]; then
          LAG_MINUTES_WAS=$(<$TRG_FILE_LAG_MINUTES)
          rm $TRG_FILE_LAG_MINUTES
          cat $ALL_VALUES | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "- RECOVER: $(date +%H:%M:%S-%d/%m/%y) standby: ${HOST_STB} was ${LAG_MINUTES_WAS}, now ${LAG_MINUTES_NOW} minuted behind (LAG_MINUTES limit = $LAG_MINUTES min)"
          echo "LAG_MINUTES recover host: "${HOST} " database: "${DB}
        fi
      else
        if [[ "$LAG_MINUTES_NOW" -ge "$LAG_MINUTES" ]]; then
          echo "$LAG_MINUTES_NOW" > "$TRG_FILE_LAG_MINUTES"
          cat $ALL_VALUES | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "- TRIGGER: $(date +%H:%M:%S-%d/%m/%y) standby: ${HOST_STB} is ${LAG_MINUTES_NOW} minutes behind (LAG_MINUTES limit = $LAG_MINUTES min)"
          echo "LAG_MINUTES trigger host: "${HOST} " database: "${DB}
        fi
      fi

      # find old trg_files more then at $REPEAT_AT minutes
      HH=$(date +%H)
      case "$HH" in
      "${REPEAT_AT}")
         FF=$(find "$TRG_FILE_SEQ_GAP" -mmin +$REPEAT_MINUTES 2>/dev/null | wc -l)
         if [[ "$FF" -eq 1 ]]; then
           CNT=$(head -1 $TRG_FILE_SEQ_GAP)
           cat $ALL_VALUES | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "- TRIGGER REPEAT: $(date +%H:%M:%S-%d/%m/%y) more ${SEQ_GAP_NOW} archivelogs not applyed to standby: ${HOST_STB} (SEQ_GAP limit = $SEQ_GAP logs)"
           echo "SEQ_GAP repeat trigger host: "${HOST} " database: "${DB}
         fi

         FF=$(find "$TRG_FILE_LAG_MINUTES" -mmin +$REPEAT_MINUTES 2>/dev/null | wc -l)
         if [[ "$FF" -eq 1 ]]; then
           CNT=$(head -1 $TRG_FILE_LAG_MINUTES)
           cat $ALL_VALUES | $BASEDIR/send_msg.sh $CONFIG $0 $HOST $DB "- TRIGGER REPEAT: $(date +%H:%M:%S-%d/%m/%y) standby: ${HOST_STB} more ${LAG_MINUTES_NOW} minutes behind (LAG_MINUTES limit = $LAG_MINUTES min)"
           echo "LAG_MINUTES repeat trigger host: "${HOST} " database: "${DB}
         fi
      ;;
      esac
   done < <(echo "$ALL_VALUES")
fi

  done
done

