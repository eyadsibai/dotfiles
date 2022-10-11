#get some display info
xset q

#Screen blank after 300 seconds and off after 420 (120 after it blanks)
xset dpms 0 300 420

#disable screen blanking and off
xset s off -dpms
#or
xset dpms 0 0 0

#force screen off (turn back on with mouse or keyboard)
xset -display :0.0 dpms force off

#Turn screen back on
xset -display :0.0 dpms force on