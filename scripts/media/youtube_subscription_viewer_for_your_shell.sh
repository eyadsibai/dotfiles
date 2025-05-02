#!/bin/bash
#created by Kris Occhipinti https://filmsbykris.com
#Copyright Jan 9th 2018
#License GPLv3 https://www.gnu.org/licenses/gpl-3.0.txt

sublist="$HOME/.ytsublist"
ua="Mozilla/5.0 (Macintosh; Intel Mac OS X 10.8; rv:21.0) G    ecko/20100101 Firefox/21.0"

ytu="https://www.youtube.com/user/"
ytc="https://www.youtube.com/channel/"

#check for sub list and create it if it does not exist
if [ ! -f $sublist ]
then
  echo "metalx1000 FilmsByKris" > $sublist
  echo "BryanLunduke BryanLunduke" >> $sublist
fi


function getSubs(){
  mapfile -t subs < <(cat $sublist|awk '{print $1 " " $2}'|tr '\n' ' ' )
  user="$(whiptail --title "Choose a Channel" --menu "MENU" 16 80 9 $subs 3>&2 2>&1 1>&3)"

  echo $user
}

function getList(){
  if [[ $user == UC* ]]
  then
    url="${ytc}${user}/videos"
  else
    url="${ytu}${user}/videos"
  fi
  wget -qO- --user-agent="$ua" "${url}/videos"|\
    grep "yt-ui-ellipsis"|\
    while read line
    do
      title="$(echo "$line"|cut -d\" -f8|\
        sed 's/&quot;//g'|sed "s/&#39;/'/g"|tr ' ' '_')"
      id="$(echo "$line"|cut -d\" -f14|cut -d\= -f2)"
      if [ "$id" != "" ]
      then
        echo "\"$id\""
        echo "\"$title\""
      fi
    done
  }

  function vidMenu(){
    vid="$(whiptail --title "Video Menu" --menu "Choose a Video" 16 80 9  \
      $(getList) 3>&2 2>&1 1>&3)"
    video="$(echo "$vid"|sed 's/"//g')"
  }

  function main(){
    getSubs
    if [ "$user" = "" ];then exit;fi
    while [ 1 ]
    do
      vidMenu
      if [ "$video" = "" ];then break;fi
     echo "$video"
     mpv "https://www.youtube.com/watch?v=$video"
   done

  }

  while [ 1 ]
  do
    main
  done