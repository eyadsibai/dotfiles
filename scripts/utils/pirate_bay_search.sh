#!/bin/bash

clear

s="https://thepiratebay.org/search"
tmp="/tmp/pb.results"

#color settings
bold=`echo -en "\e[1m"`
red=`echo -en "\e[31m"`
default=`echo -en "\e[39m"`
blue=`echo -en "\e[34m"`
reverse=`echo -en "\e[7m"`
normal=`echo -en "\e[0m"`

if [ "$1" == "" ]
then
  echo -n "${reverse}What would you like to search for:${normal} ${default}"
  read q
else
  q="$1"
fi

echo "Searching for ${bold}${red}${q}${normal}${default}..."

wget -q "$s/$q" -O-|grep '^<a href="magnet:'|while read l
do
  #mag="$(echo "$l"|cut -d\" -f2|cut -d\& -f1)"
  mag="$(echo "$l"|cut -d\" -f2)"
  title="$(echo "$l"|cut -d\= -f4|cut -d\% -f1)"
  echo "$title|$mag"
done > "$tmp"

cat -n $tmp|cut -d\| -f1

echo -n "${bold}${blue}Please select a number to download: ${default}${normal}"
read s

echo "${blue}"
echo "${default}"
d="$(sed "${s}q;d" $tmp|cut -d\| -f2)"

echo "${bold}Running Command: ${red}aria2c '$d'${default}${nomral}"
aria2c "$d"
