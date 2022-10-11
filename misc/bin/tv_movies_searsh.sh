#!/bin/bash

######################################################################
#Copyright (C) 2019  Kris Occhipinti
#https://filmsbykris.com

#This program is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.

#This program is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#GNU General Public License for more details.

#You should have received a copy of the GNU General Public License
#along with this program.  If not, see <http://www.gnu.org/licenses/>.
######################################################################

site="https://ww2.watch-series.co"

echo -n "Search: "
read q

output="$(wget -qO- "$site/search.html?keyword=$q")"

select="$(echo "$output"|grep 'href="/series/'|cut -d\" -f6|sort -u|fzf)"

  echo "$select selected"

  url="${site}$(echo "$output"|grep "$select"|head -n1|cut -d\" -f2)"
  echo "${url}"
  output="$(wget -qO- "${url}")"

#check if it is a movie or show
season="$(basename $url)/season"
echo "$output"|grep "$season" > /dev/null

o="$?"

if [ "$o" = "0" ]
then
  type="tv"
  echo "TV Series"
else
  type="movie"
  echo "Movie"
  fi
