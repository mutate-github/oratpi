#!/bin/bash
set -f

# usage: echo "body message" | ttlgrm_bot.sh config MSG_FRM_SRV1 HOST1 DB1

CONFIG=$1
MPREFIX=$2
HOST=$3
DB=$4
shift
shift
shift
shift
ALL=$*

msg=$(cat; echo x)
msg=${msg%x}

BASEDIR=$(dirname $0)
TLGRM_CMD=$($BASEDIR/iniget.sh $CONFIG telegram cmd)
TLGRM_CHT=$($BASEDIR/iniget.sh $CONFIG telegram chat_id)
TLGRM_URL=$($BASEDIR/iniget.sh $CONFIG telegram url)
# for send through telegram bot script get from TLGRM_CMD
# $TLGRM_CMD mark0 $TLGRM_CHT "\`\`\` sender: ${MPREFIX} ${HOST}/${DB} ${ALL}
# ${msg} \`\`\`"

# send from curl
text="\`\`\`
sender: ${MPREFIX} ${HOST}/${DB} ${ALL}
${msg}
\`\`\`
"
curl -X POST "${TLGRM_URL}" \
     -d "chat_id=${TLGRM_CHT}" \
     -d "text=$text" \
     -d "parse_mode=markdown"

