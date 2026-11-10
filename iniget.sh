#!/bin/bash
# usage: iniget.sh <file> --list | <section> [key]
iniget() {
  local file=$1 sec=$2 key=${3-}
  [[ -f $file && -n $sec ]] || { echo "usage: iniget <file> [--list|<section> [key]]" >&2; return 1; }
  awk -v sec="$sec" -v key="$key" '
    { sub(/\r$/, "") }                                  # CRLF
    /^[ \t]*[#;]/ || /^[ \t]*$/ { next }                # комментарий только с начала строки
    /^[ \t]*\[[^]]+\][ \t]*([#;].*)?$/ {                # заголовок секции
      s = $0; sub(/^[ \t]*\[/, "", s); sub(/\].*$/, "", s)
      if (sec == "--list") print s
      insec = (s == sec); next                          # точное сравнение
    }
    insec {
      line = $0; sub(/^[ \t]+/, "", line)
      if (key == "") { print line; next }
      p = index(line, "="); if (!p) next
      k = substr(line, 1, p - 1); sub(/[ \t]+$/, "", k)
      if (k == key) { v = substr(line, p + 1); sub(/^[ \t]+/, "", v); sub(/[ \t]+$/, "", v); print v }
    }' "$file"
}
BASEDIR=$(dirname "$0")
cfg=$1; [[ $cfg = /* ]] || cfg=$BASEDIR/$cfg
shift
iniget "$cfg" "$@"

