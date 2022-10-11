#!/bin/bash

# Dirty script to download covers for the album of currently playing song by mpd
# with glyrc

# Copyright (c) 2013  Vyacheslav Levit
# Licensed under The MIT License: http://opensource.org/licenses/MIT

export MUSIC_DIR="$HOME/music"
export TEMPDIR=/var/tmp
VIEWER=(qiv -tB)
COVER='/tmp/cover.png'

"${VIEWER}" "$COVER"
