#!/bin/bash
#created by Kris Occhipinti https://filmsbykris.com
#Copyright Jan 20th 2018
#License GPLv3 https://www.gnu.org/licenses/gpl-3.0.txt

goback="1day"
ytdir="$HOME/.ytsubs"
subs="$ytdir/ytsubs.lst"
current="$ytdir/current.lst"
viewed="$ytdir/viewed.lst"
tmp="/tmp/ytsubs.lst"
tmp2="/tmp/ytsubs.tmp"

format="22"
func=$1
length=0
videos=()

#text Editor
editor="vim"

#max wait time while pulling video list
wait=30

function main(){
  checkFiles
  if [ "$func" == "get" ]
  then
    getCurrent
  elif [ "$func" == "all" ]
  then
    all=true
    showList
  elif [ "$func" == "list" ]
  then
    $editor $subs
  elif [ "$func" == "help" ]
  then
    help
  else
    showList
  fi
}

function help(){
  echo -e "\e[7m Options: \e[0m"
  echo -e "\e[32m$0 get \e[37m#updates video list"
  echo -e "\e[32m$0 list \e[37m#edit list of subscriptions"
  echo -e ""
  echo -e "\e[7m Usefull: \e[0m"
  echo -e "Add $0 to your conjobs"

  echo ""
  controls
}

function checkFiles(){
  if [ ! -d $ytdir ] 
  then
    mkdir -p $ytdir
  fi

  if [ ! -f $subs ]
  then
    echo "metalx1000" > $subs
    echo "BryanLunduke" >> $subs
  fi
}

function getCurrent(){
  #remove old list
  rm "$tmp"
  echo "Saving to $current"
  cat $subs|sort -u|while read sub;do
  echo -n "Getting ${sub}'s Video List..."
  timeout $wait youtube-dl -ciwgef $format --dateafter=now-$goback ytuser:$sub 2>/dev/null|\
    while read line
    do
      if [[ $line != *"http"* ]];
      then
        echo "$sub - $line"|sed 's/&/and/g;s/\[//g;s/\]//g;' >> "$tmp" 
      else
        echo "$line" >> "$tmp"
      fi
    done
    echo ""
  done

  mv "$tmp" "$current"
  echo "$current updated."
}

function playVideo(){
  echo "Playing $1..."
  echo "$1" >> $viewed
  url="$(grep "$1" -A 1 $current|tail -n 1)"
  echo "$url"
  mpv "$url"
}

function controls(){
  echo -e "\e[1m\e[4mKeys: w=up;s=down;e=select;q=quit\e[0m"
}

function removeViewed(){
  cp $current $tmp2
  cat $viewed|sort -u|grep -v '^http'|while read l;
do 
  sed -i "/$l/d" $tmp2
done
grep -v '^http' $tmp2|sort -u
}


function showList(){
  if [ $all ]
  then
    IFS=$'\r\n' GLOBIGNORE='*' command eval  'videos=($(grep -v "^http" $current))'
  else
    removeViewed
    IFS=$'\r\n' GLOBIGNORE='*' command eval  'videos=($(removeViewed))'
  fi
  length="${#videos[@]}"
  let x=0;
  while [ 1 ]
  do
    clear
    controls
    for (( i=0; i<$length;i++ ));
    do
      if [ "$i" = "$x" ]
      then
        echo -e "\e[7m${videos[$i]}\e[0m"
      else
        echo "${videos[$i]}"
      fi
    done

    read -rsn1 k

    case $k in
      "s") let x++;;
      "w") let x--;;
      "q") echo "Goodbye...";exit 0;;
      "e") playVideo "${videos[$x]}";;
    esac

    if [ $x -lt 0 ]
    then
      let x=0;
    elif [ $x -ge $length ]
    then
      let x=$length-1;
    fi

  done
}

main