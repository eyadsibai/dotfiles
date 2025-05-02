#!/bin/bash
artist= "$(mpc -f %artist% | head -n 1)"
title= "$(mpc -f %title% | head -n 1)"
song=`curl -s --get "https://makeitpersonal.co/lyrics" --data-urlencode "artist=$artist" --data-urlencode "title=$title"`

echo -e "$artist - $title\n$song"
