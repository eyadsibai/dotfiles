#!/bin/bash

sleep 2 
import -window root /tmp/screen.png
#pat file created with png2pat
loc="$(visgrep /tmp/screen.png /tmp/pattern.pat)"

if [ "$loc" == "" ];then
  echo "Not Found"
else
  x="$(echo $(echo "$loc"|cut -d\  -f1|cut -d\, -f1)+20|bc)"
  echo "x=$x"

  y="$(echo $(echo "$loc"|cut -d\  -f1|cut -d\, -f2)+20|bc)"
  echo "y=$y"

  xte "mousemove $x $y" "sleep 1" "mouseclick 1"
fi