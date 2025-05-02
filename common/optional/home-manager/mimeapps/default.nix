{ config, pkgs, lib, username, ... }:
{
  # Centralized MIME type associations
  xdg.mimeApps = {
    enable = true; # Ensure this is enabled if not enabled elsewhere
    defaultApplications = {
      # Web Browsers (adjust based on installed/preferred)
      "text/html" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" "code.desktop" ];
      "application/x-extension-htm" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "application/x-extension-html" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "application/x-extension-shtml" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "application/x-extension-xht" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "application/x-extension-xhtml" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "application/xhtml+xml" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "x-scheme-handler/chrome" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "x-scheme-handler/ftp" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "x-scheme-handler/http" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "x-scheme-handler/https" = [ "org.qutebrowser.qutebrowser.desktop" "firefox.desktop" ];
      "x-scheme-handler/webcal" = [ "firefox.desktop" ]; # Or calendar app?
      "x-scheme-handler/mailto" = [ "firefox.desktop" ]; # Or mail client?

      # Text / Code / Config
      "text/csv" = [ "code.desktop" ];
      "text/markdown" = [ "code.desktop" ];
      "text/plain" = [ "code.desktop" ];
      "text/x-python3" = [ "code.desktop" ];
      "text/x-python" = [ "code.desktop" ];
      "text/x-tex" = [ "code.desktop" ];
      "application/x-yaml" = [ "code.desktop" ];
      "application/json" = [ "code.desktop" ];
      "application/xml" = [ "code.desktop" ];
      "application/x-gettext-translation" = [ "code.desktop" ];
      "application/x-wine-extension-ini" = [ "code.desktop" ]; # If using Wine

      # PDF
      "application/pdf" = [ "org.pwmt.zathura-pdf-mupdf.desktop" ];

      # Video
      "video/mp4" = [ "mpv.desktop" ];
      "video/ogg" = [ "mpv.desktop" ];
      "video/x-flv" = [ "mpv.desktop" ];
      "video/x-ms-wmv" = [ "mpv.desktop" ];
      "video/x-ogm+ogg" = [ "mpv.desktop" ];
      "video/x-theora+ogg" = [ "mpv.desktop" ];

      # Audio
      "audio/x-wav" = [ "mpv.desktop" ]; # Or dedicated audio player

      # Images
      "image/gif" = [ "feh.desktop" "viewnior.desktop" "gimp.desktop" ];
      "image/jpeg" = [ "feh.desktop" "viewnior.desktop" "gpicview.desktop" ]; # gpicview?
      "image/png" = [ "feh.desktop" "viewnior.desktop" "gpicview.desktop" ]; # gpicview?

      # Communication / Social
      "x-schema-handler/msteams" = [ "teams.desktop" ]; # If using Teams
      "x-scheme-handler/tg" = [ "userapp-Telegram Desktop-8UD5R1.desktop" "userapp-Kotatogram Desktop-CIMGS1.desktop" ]; # Adjust based on actual desktop file names

      # Archives (Example - uncomment/adjust if needed)
      # "application/zip" = [ "engrampa.desktop" ];
      # "application/x-rar" = [ "engrampa.desktop" ];
      # "application/x-7z-compressed" = [ "engrampa.desktop" ];

      # Other (Examples - uncomment/adjust if needed)
      # "application/octet-stream" = [ "mousepad.desktop" ]; # Generic binary data
      # "application/x-bittorrent" = [ "deluge.desktop" ];
      # "application/x-ms-dos-executable" = [ "wine.desktop" ]; # If using Wine
      # "inode/directory" = [ "pcmanfm.desktop" ]; # File manager
      # "message/rfc822" = [ "userapp-Thunderbird.desktop" ]; # Email
      # "x-scheme-handler/jetbrains" = [ "jetbrains-toolbox.desktop" ];
      # "x-scheme-handler/notion" = [ "notion-app-enhanced.desktop" ];
      # "x-scheme-handler/ssh" = [ "Hyper.desktop" ]; # Or terminal
    };

    # Added Associations (Example - if needed for 'Open With...' menus)
    # addedAssociations = {
    #   "text/plain" = [ "gedit.desktop" "nvim.desktop" ];
    # };
  };
}
