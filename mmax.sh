#!/bin/bash

set -f

# usage: echo "body message" | mmax.sh config MSG_FRM_SRV1 HOST1 DB1

CONFIG=$1
MPREFIX=$2
HOST=$3
DB=$4
shift
shift
shift
shift
ALL=$*

msg=$(cat; echo -e x)
msg=${msg%x}

BASEDIR=$(dirname $0)
MAX_CHT=$($BASEDIR/iniget.sh $CONFIG max chat_id)
MAX_URL=$($BASEDIR/iniget.sh $CONFIG max url)

# echo "MAX_URL: "$MAX_URL
# echo "MAX_CHT: "$MAX_CHT

# send from curl
text="sender ${MPREFIX} ${HOST} ${DB} ${ALL} \n ${msg}"

# text=$(tr -d '[[:cntrl:]]' <<< $text)
# text=$(awk '{sub("\r","");print}' | tr -d '[[:cntrl:]]' <<< $text)
# text=$(awk '{sub("\r","");print}'  <<< $text)
text=$(tr -d '[[:cntrl:]]'  <<< $text)

# echo "------------"
# echo -e "text_xxd: "$(xxd <<< $text)
# echo "------------"
# echo -e "text: "${text}
# echo "------------"

# echo "curl --location ${MAX_URL} --header 'Content-Type: application/json' --data-raw \"{ \"chatId\": \"${MAX_CHT}\", \"message\": \"${text}\" }\" "

curl --location ${MAX_URL} --header 'Content-Type: application/json' --data-raw "{ \"chatId\": \"${MAX_CHT}\", \"message\": \"${text}\" }"

