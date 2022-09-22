#!/usr/bin/env bash

#####load new fonts on Linux#####

##for local user##
#for system wide usage /usr/share/fonts/truetype/ should work
#make font dir and move font files there
mkdir -p $HOME/.local/share/fonts
cp *.ttf $HOME/.local/share/fonts

#update fonts to system
fc-cache -f -v
