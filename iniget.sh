#!/bin/bash

#[Machine1]
#app=version1
#[Machine2]
#app=version1
#app=version2
#[Machine3]
#app=version1
#app=version3

# iniget file.ini --list
# $ iniget file.ini Machine3
# $ iniget file.ini Machine1 app

function iniget() {
  if [[ $# -lt 2 || ! -f $1 ]]; then
    echo "usage: iniget <file> [--list|<section> [key]]"
    return 1
  fi
  local inifile=$1

  if [ "$2" == "--list" ]; then
    for section in $(cat $inifile | sed '/ *#/d; /^ *$/d' | grep "\[" | sed -e "s#\[##g" | sed -e "s#\]##g"); do
      echo $section
    done
    return 0
  fi

  local section=$2
  local key
  [ $# -eq 3 ] && key=$3

  # This awk line turns ini sections => [section-name]key=value
#  local lines=$(awk '/\[/{prefix=$0; next} $1{print prefix $0}' $inifile)
  local lines=$(awk '/\[/{prefix=$0; gsub(/[ \t]+$/,"",prefix); next} $1{print prefix $0}' $inifile | sed '/ *#/d; /^ *$/d')
  while read line; do
    if [[ "$line" =~ \[$section\]* ]]; then
      local keyval=$(echo $line | sed -e "s/^\[$section\]//")
      if [[ -z "$key" ]]; then
        echo $keyval
      else
        if [[ "$keyval" = $key=* ]]; then
          echo $(echo $keyval | sed -e "s/^$key=//")
        fi
      fi
    fi
  done < <(echo "$lines")
}


BASEDIR=`dirname $0`

iniget $BASEDIR/$1 $2 $3

