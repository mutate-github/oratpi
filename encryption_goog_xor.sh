#!/bin/bash
# https://9to5answer.com/bitwise-xor-a-string-in-bash
set -f

ascii2dec()
{
  RES=""
  for i in `echo $1 | sed "s/./& /g"`; do
    RES="$RES/`printf \"%d\" \"'$i\"`"
  done
  echo $RES
}

dec2ascii()
{
  RES=""
  for i in `echo $* | sed 's|/| |g'`; do
    RES="$RES`printf \\\\$(printf '%03o' $i)`"
  done
  echo $RES
}

xor()
{
  KEY=$1
  shift
  RES=""
  for i in `echo $* | sed 's|/| |g'`; do
    RES="$RES/$(($i ^$KEY))"
  done

  echo $RES
}


KEY=127

if [ -z "$1" ]; then
  TESTSTRING="QWERTYUIOPASDFGHJKLZXCVBNMqwertyuiopasdfghjklzxcvbnm[]\;,./?=+-_0987654321)(*&^%$#@!~"
else
  TESTSTRING="$1"
fi

echo "Original String: $TESTSTRING"

STR_DATA=$(ascii2dec "$TESTSTRING")
echo "Original String Data: $STR_DATA"

XORED_DATA=$(xor $KEY $STR_DATA)
echo "XOR-ed Data: $XORED_DATA"

RESTORED_DATA=$(xor $KEY $XORED_DATA)
echo "Restored Data: $RESTORED_DATA"

RESTORED_STR=$(dec2ascii $RESTORED_DATA)
echo "Restored String: $RESTORED_STR"

echo "restored from encrypted .........."
RESTORED_DATA=$(xor $KEY $TESTSTRING)
echo "Restored Data: $RESTORED_DATA"

RESTORED_STR=$(dec2ascii $RESTORED_DATA)
echo "Restored String: $RESTORED_STR"

