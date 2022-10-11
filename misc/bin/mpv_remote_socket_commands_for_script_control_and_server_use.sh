#MPV remote control shell commands 
#set things up by installing needed programs
sudo apt install mpv youtube-dl socat

#start service and create file to write to
mpv --idle --input-ipc-server=/tmp/mpvsocket

#load file
#this example is playing a youtube video so youtube-dl is needed
echo loadfile "https://www.youtube.com/watch?v=JSiLviAsX6M"|socat - /tmp/mpvsocket

#or if you want json response you can use json to run commands
echo '{ "command": ["loadfile", "https://www.youtube.com/watch?v=HeeE1XIxHzg"] }'| socat - /tmp/mpvsocket

#Pause file 
echo '{ "command": ["set_property", "pause", true] }'| socat - /tmp/mpvsocket

#unpause file
echo '{ "command": ["set_property", "pause", false] }'| socat - /tmp/mpvsocket

#to append another file to the end of the playlist
echo loadfile "https://www.youtube.com/watch?v=Gzn396wr9AY" append-play |socat - /tmp/mpvsocket

#seek forward and back in seconds
echo '{ "command": [ "seek", "+1" ] }' | socat - /tmp/mpvsocket
echo '{ "command": [ "seek", "-1" ] }' | socat - /tmp/mpvsocket

###the above commands don't show the OSD (On Screen Display)
#if you want, you can send keypresses instead, which will show OSD
echo '{ "command": [ "keypress", "right" ] }' | socat - /tmp/mpv.socket
echo '{ "command": [ "keypress", "left" ] }' | socat - /tmp/mpvsocket
echo '{ "command": [ "keypress", "up" ] }' | socat - /tmp/mpvsocket
echo '{ "command": [ "keypress", "down" ] }' | socat - /tmp/mpvsocket
##get a full list of keys with this command
mpv --input-keylist

#you can list all options like this
mpv --list-properties

#or, if you know the shortcut keys, you can always use them
echo '{ "command": [ "keypress", "]" ] }' | socat - /tmp/mpvsocket #speed up
echo '{ "command": [ "keypress", "[" ] }' | socat - /tmp/mpvsocket #slow down
#reset speed by sending BACKSPACE key list this
echo '{ "command": [ "keypress", "BS" ] }' | socat - /tmp/mpvsocket

#screenshot
echo '{ "command": [ "keypress", "s" ] }' | socat - /tmp/mpvsocket 

###other commands
#send your own message to screen
echo '{"command":["show-text","This is a message"]}' | socat - /tmp/mpvsocket

#show OSD of current position
echo show-progress | socat - /tmp/mpvsocket

#i3 keybindings
bindsym XF86AudioPlay  exec echo cycle pause   | socat - /tmp/mpvsocket
bindsym XF86AudioPause exec echo cycle pause   | socat - /tmp/mpvsocket
bindsym XF86AudioStop  exec echo cycle pause   | socat - /tmp/mpvsocket
bindsym XF86AudioPrev  exec echo playlist_prev | socat - /tmp/mpvsocket
bindsym XF86AudioNext  exec echo playlist_next | socat - /tmp/mpvsocket