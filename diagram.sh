#!/bin/bash
set -f

printf "usage: ./diagram.sh sysmetric_h.log 25/11/23-0[89]  3 11 15 17 19 20 22 23 24 \n"
printf "usage: tpi ... oratop h          | diagram.sh  3 10 14 17 19 20 22 23 24 26 \n"
printf "usage: tpi ... oratop dhsh       | diagram.sh  2 5 6 9 10 11 13 14 15 17 18 21 23 24 \n"
printf "usage: tpi ... dhash uchart      | diagram.sh  2 3 6 7 8 9 10 13 16 \n"
printf "usage: tpi ... dhash iostat      | diagram.sh  2 3 4 5 6 7 8 9 10 11 12 13 \n"
printf "usage: tpi ... dhash segstat . . | diagram.sh  5 6 7 8 9 10 11 12 13 14 15 \n"
printf "usage: tpi ... dhash awrinfo     | diagram.sh  2 7 8 9 10 11 12 13 16 17 20 21 22 23 \n"
echo ""

if [[ "$2" =~ "/" || "$#" -eq 0 ]]; then
  all_par="3 11 15 17 19 20 22 23 24"
else
  all_par="$@"
fi

if [ -p /dev/stdin ]; then
  file="/tmp/$$_tmp.tmp"
  stdin=$(cat)
  echo "$stdin" > $file
  date="^[0-9][0-9]\/.*"
else
  file="$1"
  date="$2"
  shift
  shift
  if [[ "$#" -ne 0 ]]; then  all_par="$@"; fi
  if [[ "$#" -eq 0 ]]; then  : ; fi
  # col1="$3"
  # col2="$4"
fi

col1="1"
limit=15
histo="|=======================================================================+"
scale=$(awk "BEGIN{print $limit/100}")

tail -10000 "${file}" | grep "BEGIN_TIME" | uniq > ${file}.tmp
if [[ "$#" -eq 0 ]]; then all_par=$(seq 2 $(awk '{print NF}' ${file}.tmp)); echo "debug all_par: " $all_par; fi
# egrep "${date}" "${file}" | sort -n | uniq >> ${file}.tmp
egrep "^${date}" "${file}" | uniq >> ${file}.tmp
rm /tmp/$$_tmp.tmp 2>/dev/null
file=${file}.tmp

get_cols()
{
col2="$1"
max=`awk '/^[0-9].*/{if ($'${col2}'>x) x=$'${col2}'};END{print x}' $file`
# if [[ -z "$max" || "$max" -eq 0 ]]; then max=1; fi
rc=$(echo "$max"'=='0 | bc -l 2>/dev/null)
if [[ -z "$max" || "$rc" -eq 1 ]]; then max=1; fi

cat $file | awk '!/---/{print $'$col1'" "$'$col2'}' | xargs -n2 echo | while read datewd value ; do
   printf "%-20s" $datewd
   printf "%-11s" $value
   if [[ "$datewd" = "BEGIN_TIME" ]]; then
      printf "%-${limit}s" LEVELS
   fi
   value=$(awk "BEGIN{printf \"%3d\", ($value / ($max / 100)) * $scale}")
   if [[ "$value" -lt 1 && "$datewd" != "BEGIN_TIME" ]]; then value=1; fi
#   echo $value " " $result
   printf ${histo:0:$value}"\n"
done
}

awk '{print $1}' ${file} > /tmp/0_$$.tmp

for i in $(xargs -n1 echo <<< "$all_par"); do
	get_cols $i | awk '{printf $2" "$3"\n"}' > /tmp/c_$$_${i}.tmp
  j=$j" "/tmp/c_$$_${i}.tmp
done

paste /tmp/0_$$.tmp $j | column -t

rm $file /tmp/0_$$.tmp $j

