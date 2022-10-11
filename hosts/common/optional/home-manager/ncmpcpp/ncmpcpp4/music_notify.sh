#!/bin/bash
status=$(echo $(mpc status|sed -n 2p|cut -d " " -f 1))
MUSIC_DIR="$HOME/music"


albumName=$(ncmpcpp -q --current-song='%b')
artistName=$(ncmpcpp -q --current-song='%a')
albumNameNoDots=$(echo $albumName|sed "s/[\,\.]/ /g")

albumPath="$MUSIC_DIR/$albumNameNoDots"
mkdir -p "$albumPath"
coverArtPath=$(find "$albumPath" -name "*.jp*g" -or -name "*.png")
# coverArtPath=("$albumPath"/*.png)
echo "albumPath: $albumPath"
echo "coverArtPath: $coverArtPath"
echo "albumNameNoDots: $albumNameNoDots"


case $coverArtPath in
    *"podcast"*)
	echo true
	;;
    *"//"*)
	echo empty
	;;
    *)
	echo notAPodcast
	getCover= [ -f "$coverArtPath" ] || glyrc cover --artist "$artistName" --album "$albumNameNoDots" -z 10 -w "$albumPath" 2>/dev/null
	;;
esac


coverArtPath=$(find "$albumPath" -name "*.jp*g" -or -name "*.png")
echo "$albumNameNoDots"
echo "$albumName"
echo "$artistName"
echo "$albumArt"
case $status  in
    "[playing]")
	notify-send -a mpd -t 2000 -i "$coverArtPath"  "$(ncmpcpp -q --current-song='%t')" "$albumName\n$artistName"
	echo "$coverArtPath"
	cp "$coverArtPath" /tmp/cover.png

	;;
    "[paused]")
	;;
esac
