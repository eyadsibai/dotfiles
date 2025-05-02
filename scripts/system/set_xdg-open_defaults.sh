#set default applications for xdg-open
#Get list of programs
ls /usr/share/applications/

#web browser
xdg-settings set default-web-browser chromium.desktop

#for file manager/browser
xdg-mime default pcmanfm.desktop inode/directory