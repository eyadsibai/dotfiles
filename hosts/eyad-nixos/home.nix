{ config
, pkgs
, lib
, username
, ...
}:
let
  sysConfig = config;
  homeConfig = config.home-manager.users.${username};


in
{
  home-manager.users.${username} = {
    programs.kakoune.enable = true;
    programs.yt-dlp.enable = true;
    programs.gallery-dl.enable = true;
    home.enableNixpkgsReleaseCheck = true;
    imports = [
      ../common/optional/home-manager/bitwarden
      ../common/optional/home-manager/development.nix
      ../common/optional/home-manager/direnv
      ../common/optional/home-manager/discord
      # ../../common/optional/home-manager/email_cal_rss.nix
      ../common/optional/home-manager/firefox
      ../common/optional/home-manager/flameshot
      ../common/optional/home-manager/gtk
      ../common/optional/home-manager/htop
      ../common/optional/home-manager/kaggle
      # ../../common/optional/home-manager/khard
      ../common/optional/home-manager/kitty
      ../common/optional/home-manager/media.nix
      ../common/optional/home-manager/menu
      ../common/optional/home-manager/micro
      ../common/optional/home-manager/mpv
      ../common/optional/home-manager/neovim
      ../common/optional/home-manager/networkmanager_dmenu
      ../common/optional/home-manager/newsboat
      ../common/optional/home-manager/ngrok
      ../common/optional/home-manager/office.nix
      ../common/optional/home-manager/qutebrowser
      ../common/optional/home-manager/services.nix
      ../common/optional/home-manager/social
      ../common/optional/home-manager/spotify
      #     ../common/optional/home-manager/sxhkd
      ../common/optional/home-manager/system.nix
      ../common/optional/home-manager/terminal
      ../common/optional/home-manager/udiskie
      ../common/optional/home-manager/zathura
      # ../../common/optional/home-manager/accounts
      ../common/optional/home-manager/pyradio

      # Newly modularized configs
      ../common/optional/home-manager/dunst
      ../common/optional/home-manager/mimeapps
    ];

    # Dunst configuration moved to common/optional/home-manager/dunst/default.nix

    xdg.configFile."wget/wgetrc".text = ''
      hsts-file=~/.cache/wget-hsts
    '';

    xdg.configFile."pudb/pudb.cfg".text = ''
      [pudb]
        breakpoints_weight = 1
        current_stack_frame = top
        custom_shell =
        custom_stringifier =
        custom_theme =
        default_variables_access_level = public
        display = auto
        hide_cmdline_win = False
        line_numbers = True
        prompt_on_quit = True
        seen_welcome = e039
        shell = ipython
        sidebar_width = 0.5
        stack_weight = 1
        stringifier = type
        theme = midnight
        variables_weight = 1
        wrap_variables = True
    '';

    xdg.userDirs = {
      desktop = "$HOME/Desktop";
      documents = "$HOME/Documents";
      download = "$HOME/Downloads";
      music = "$HOME/Music";
      pictures = "$HOME/Pictures";
      videos = "$HOME/Videos";
      publicShare = "$HOME/Public";
      templates = "$HOME/Templates";
    };
    services.kdeconnect = {
      enable = false;
      # package = pkgs.plasma5Packages.kdeconnect-kde;
    };

    home.preferredApps = {
      menu = {
        run-cmd = "rofi -show run";
        drun-cmd = "rofi -show drun";
        dmenu-cmd = "rofi -dmenu";
        password-cmd = "rofi-rbw";
      };

      terminal = {
        cmd = "kitty -1";
        cmd-spawn = program: "kitty -1 $SHELL -i -c ${program}";
      };

      mail = {
        cmd = homeConfig.home.preferredApps.terminal.cmd-spawn "neomutt";
      };
      browser = {
        cmd = "qutebrowser";
      };

      notifier = {
        cmd = "";
      };
      editor = {
        cmd = "";
      };
    };

    home.file.".condarc".text = ''
      channels:
        - defaults
        - conda-forge

      always_yes: true

      track_features:
        - nomkl

      auto_activate_base: false
    '';

    home.sessionVariables = rec {
      XDG_CACHE_HOME = "\${HOME}/.cache";
      XDG_CONFIG_HOME = "\${HOME}/.config";
      XDG_BIN_HOME = "\${HOME}/.local/bin";
      XDG_DATA_HOME = "\${HOME}/.local/share";
      # PATH = [
      #   "\${XDG_BIN_HOME}"
      # ];
      BROWSER = "${lib.getExe pkgs.qutebrowser}"; # Consistent with preferredApps
      MOZ_USE_XINPUT2 = "1"; # for firefox touchpad support
    };
    # MIME Apps configuration moved to common/optional/home-manager/mimeapps/default.nix

    services.safeeyes = {
      # enable = true;
    };

    programs.tmate.enable = false;
    # programs.pls.enable = true;
    xdg.configFile."yandex-disk/config.cfg" = lib.mkIf (builtins.elem pkgs.yandex-disk homeConfig.home.packages) {
      text = ''
        auth="/home/eyad/.config/yandex-disk/passwd"
        dir="/home/eyad/Yandex.Disk"
        proxy="no"
        exclude-dirs="from_mac,photostructure,from_dropbox,audio_books,games,photos,ebooks,Screenshots,papers,movies,videos,visual_computing/ics-502/assignments/assignment1/.direnv,visual_computing/ics-502/assignments/assignment2/.direnv"
      '';
    };

    # TODO https://github.com/LukeSmithxyz/voidrice/
    # https://github.com/mitchellh/nixos-config
    # https://github.com/jwiegley/nix-config
    # Nicely reload system units when changing configs
    systemd.user.startServices = "sd-switch";
    # news.display = "silent";

    # It's generally recommended to install packages via specific program/service
    # options in Home Manager when available (e.g., programs.htop.enable = true)
    # instead of listing them in home.packages, as this often sets up
    # configurations or services associated with the package.
    # Packages listed here are those without specific Home Manager modules or
    # where only the package itself is needed.
    home.packages = with pkgs; [
      # Dev Tools
      cookiecutter
      git-crypt
      flakify # Personal pkg?
      graphviz
      curlFull.dev # Includes headers/libs
      dialog # TUI dialog boxes
      ditaa # ASCII diagrams -> real diagrams
      drawio # Diagramming tool
      highlight # Syntax highlighting
      # httpie # User-friendly curl alternative
      # httping # Ping over HTTP/S
      hyperfine # Benchmarking tool
      kaggle # Kaggle CLI
      ngrok # Tunneling
      statix # Linter/formatter for Nix
      exercism # Coding practice platform CLI
      yq # YAML processor (like jq for JSON)
      sd # Intuitive find & replace CLI (alternative to sed)
      meld # Visual diff and merge tool
      colordiff # Colorized diff output
      file # Determine file type
      # gdb # Debugger
      # patchelf # Modify ELF executables

      # Shell & Terminal Utils
      arandr # GUI for xrandr
      atool # Archive tool wrapper (tar, zip, etc.)
      bitwarden-cli # Bitwarden CLI
      brightnessctl # Backlight control
      catimg # Image preview in terminal
      # chafa # Advanced image/graphics in terminal
      # clerk # Task runner? Needs context
      cntr # Container debugging tool
      # cobang # QR code scanner? Needs context
      # cointop # Crypto TUI
      colorz # Color scheme generator from image
      ddgr # DuckDuckGo from terminal
      duf # Disk usage/free TUI
      fd # Fast file finder (alternative to find)
      fdupes # Duplicate file finder
      fff # Simple file manager TUI
      glow # Markdown renderer TUI
      gotty # Share terminal as web app
      jmtpfs # Mount MTP devices (Android)
      jp2a # JPEG to ASCII
      libnotify # For notify-send command
      mc # Midnight Commander file manager
      mpc_cli # MPD client CLI
      multilockscreen # X11 screen locker script?
      ncpamixer # ncurses PulseAudio mixer
      neofetch # System info script
      nethogs # Per-process network bandwidth TUI
      nettools # Classic networking tools (ifconfig, netstat)
      nitrogen # X11 wallpaper setter
      nload # Network usage monitor TUI
      nyancat # Famous rainbow cat!
      pavucontrol # PulseAudio volume control GUI
      # playerctl # Media player control CLI
      prettyping # Nicer ping output
      pulsemixer # PulseAudio mixer TUI
      # remind # Calendar/reminder system
      rclone # Cloud storage sync tool
      # reaverwps-t6x # WPS cracking tool? Security risk?
      # ripgrep # Fast grep alternative (usually installed via programs.ripgrep.enable)
      rlwrap # Readline wrapper
      rmlint # Lint tool for finding duplicates/waste
      # sc-im # Spreadsheet calculator TUI
      screenkey # Display keystrokes on screen
      speedtest-cli # Internet speed test
      # stig # Git TUI? Needs context
      sysstat # System monitoring tools (iostat, mpstat)
      tcpdump # Network packet analyzer
      teleport # Modern SSH alternative
      termdown # Terminal countdown timer
      # termshark # Wireshark TUI
      tldr # Simplified man pages
      tree # Display directory structure
      tty-clock # Clock in terminal
      units # Unit conversion tool
      urlscan # Scan URLs for malicious content? Needs context
      extract_url # Extract URLs from text? Needs context
      w3m # Text-based web browser
      # wavemon # Wireless network monitor TUI
      # wpgtk # Wallpaper theming tool
      xdotool # X11 automation tool
      xdragon # X11 drag-and-drop utility
      xsel # X11 clipboard utility
      xan # Needs context
      yad # Dialog box generator (like zenity)
      # vdirsyncer # CalDAV/CardDAV sync
      zip # Zip archive tool
      # zotero # Reference manager (often installed via nixpkgs.zotero)
      # obsidian # Note-taking app (often installed via nixpkgs.obsidian)
      peek # GIF screen recorder
      imagemagick # Image manipulation tools
      onionshare # Secure file sharing over Tor
      # nur.* # Packages from NUR - ensure trust
      yandex-disk # Yandex Disk client
      # upwork # Upwork client? Needs context
      jrnl # Command-line journal
      gparted # Partition editor GUI
      # python310Packages.mistune_2_0 # Specific python lib version? Why?
      # notion-app-enhanced # Notion client?
      pfetch # Minimal system fetch script
      usbutils # lsusb etc.
      dogdns # DNS client over HTTPS/TLS
      # sherlock # Username finder across social networks?
      # signal-cli # Signal messenger CLI
      # signalbackup-tools # Tools for Signal backups
      # signald # Signal daemon
      turses # Twitter TUI
      twitch-tui # Twitch TUI
      iotop # I/O monitoring TUI
      ioping # Disk I/O latency tester
      ncdu # Disk usage analyzer TUI
      iftop # Network bandwidth TUI (by connection)
      ethtool # Ethernet card settings tool
      gotop # System monitor TUI
      gtop # System monitor TUI
      procs # Modern `ps` alternative
      sxiv # Simple X image viewer
      pgcli # Postgres CLI with completion/highlighting
      mycli # MySQL CLI with completion/highlighting
      # iredis # Redis CLI with completion/highlighting
      usql # Universal SQL CLI
      # mathematica # Proprietary software
      # lutris # Game launcher
      # coursera-dl # Coursera course downloader
      sfeed # Simple RSS/Atom parser
      pdfarranger # Merge, split, rotate PDFs
      # pdfslicer # Similar to pdfarranger
      pdfsam-basic # PDF split and merge tool
      yle-dl # Downloader for Yle Areena (Finnish)
      pdf2svg # PDF to SVG converter
      # gksu # Graphical sudo frontend (deprecated)
      # hdf5 # Data format library
      # dnsutils # dig, nslookup (often included in other packages)
      # whois # Whois client
      # coreutils # Basic utils (ls, cp, mv...) - already present
      # vbetool # Video BIOS tool
      # killall # Kill processes by name
      # binutils # Linker, assembler - usually build dependency
      # lsof # List open files
      # fam # File alteration monitor (deprecated?)
      # ghostscript # PostScript/PDF interpreter
      # sshfsFuse # Mount remote filesystems over SSH
      # gnupg # GPG encryption (use programs.gnupg.enable)
      # gnupg1orig # Older GPG version?
      # mkpasswd # Password hash generator (part of whois?)
      # openssl # SSL/TLS toolkit (often dependency)
      # gphoto2 # Camera access library
      # libmtp # MTP library (dependency for jmtpfs)
      # mtpfs # Alternative MTP filesystem?
      # nix-prefetch-git # Nix helper tool
      # ntfs3g # NTFS driver (use boot.supportedFilesystems = [ "ntfs" ])
      # cryptsetup # LUKS disk encryption tool
      # pinentry # GPG password entry (usually handled by agent)
      # python3Packages.magic-wormhole # Secure file transfer
      # croc # Secure file transfer alternative
      simple-scan # Scanner GUI
      # gwenview # KDE image viewer
      # digikam5 # Photo management
      # gimp-with-plugins # GIMP image editor (use nixpkgs.gimp)
      # bluedevil # KDE Bluetooth manager
      # josm # OpenStreetMap editor
      # blender # 3D modeling
      # qnotero # Zotero client?
      # encfs # Encrypted filesystem
      # fbreader # E-book reader
      # rssguard # RSS reader
      # feedreader # RSS reader
      # w_scan # DVB scan tool
      # audacity # Audio editor
      # simplescreenrecorder # Screen recorder (already listed above)
      # cantata # MPD client GUI
      # hugin # Panorama stitcher
      # kdenlive # Video editor
      # stable.ffmpeg-full # FFmpeg (already dependency)
      # mlt # Multimedia framework (kdenlive dep)
      # frei0r # Video effects (kdenlive dep)
      # luminanceHDR # HDR photo tool
      # gitAndTools.gitflow # Git extension
      # gitAndTools.hub # GitHub CLI wrapper
      # mosh # Mobile shell (alternative to SSH)
      # k3b # KDE CD/DVD burner
      # dvdplusrwtools # DVD burning tools
      # nixpkgs-review # Nix tool for reviewing PRs
      # stretchly # Break reminder app
      # spectacle # KDE screenshot tool
    ];
    # ++ (lib.optionals sysConfig.networking.networkmanager.enable [ stable.haskellPackages.network-manager-tui ]) # Example conditional package

    services.remmina.enable = true; # Remote desktop client
    programs.helix.enable = true; # Editor
    programs.k9s.enable = true; # Kubernetes TUI
    programs.htop.enable = true; # Process viewer TUI
    programs.feh.enable = true; # Image viewer / wallpaper setter
    programs.bottom.enable = true; # System monitor TUI (btop alternative)
    # programs.btop.enable = true; # System monitor TUI (alternative to bottom/htop)

    home.keyboard.layout = "us,ar";
    home.keyboard.options = [ "grp:win_space_toggle" ];
    xsession = {
      enable = true;
      scriptPath = ".hm-xsession";
    };
    programs.gpg.enable = true;
    programs.autojump.enable = true;
    home.stateVersion = "22.05";


  };
}
