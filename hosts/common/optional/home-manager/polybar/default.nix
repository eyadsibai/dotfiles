{ pkgs
, config
, inputs
, lib
, ...
}:
let
  inherit (config.colorscheme) colors;
in
{
  home.packages = [ pkgs.terminus_font ];

  services.polybar = {
    enable = true;
    package =
      pkgs.polybarFull.override
        {
          alsaSupport = true;
          iwSupport = true;
          pulseSupport = true;
          mpdSupport = true;
          githubSupport = true;
        };

    extraConfig = lib.concatStringsSep "\n" [
      (builtins.readFile ./bars.ini)
      (builtins.readFile ./modules.ini)
      (builtins.readFile ./user_modules.ini)
      (builtins.readFile ./config.ini)
    ];

    script = "polybar -q main &";
    config = {
      "color" = {
        background = "#${colors.base00}";
        background-alt = "#${colors.base03}";
        foreground = "#${colors.base05}";
        foreground-alt = "#${colors.base0D}";
        primary = "#${colors.base02}";

        white = "#FFFFFF";
        black = "#000000";
        red = "#EC7875";
        pink = "#EC6798";
        purple = "#BE78D1";
        blue = "#75A4CD";
        cyan = "#00C7DF";
        teal = "#00B19F";
        green = "#61C766";
        lime = "#B9C244";
        yellow = "#EBD369";
        amber = "#EDB83F";
        orange = "#E57C46";
        brown = "#AC8476";
        gray = "#9E9E9E";
        indigo = "#6C77BB";
        blue-gray = "#6D8895";
      };

      "module/distro-icon" = {
        type = "custom/script";
        exec = "${pkgs.coreutils}/bin/uname -r | ${pkgs.coreutils}/bin/cut -d- -f1";
        interval = 999999999;
        format = "%{T3}%{T-} <label>";
        format-foreground = "\${colors.background}";
        format-background = "\${color.secondary}";
        format-padding = 1;
        label = "%output%";
        # label-font = 1;
      };
    };
  };

  # config = {
  #   "global/wm" = {
  #     margin-bottom = 0;
  #     margin-top = 0;
  #   };
  #   #====================BARS====================#
  #   "bar/top" = {
  #     bottom = false;
  #     fixed-center = true;
  #     width = "100%";
  #     height = 14;
  #     offset-x = "1%";
  #     scroll-up = "i3wm-wsnext";
  #     scroll-down = "i3wm-wsprev";
  #     background = "${colors.base00}";
  #     foreground = "${colors.base05}";
  #     radius = 0;
  #     font-0 = "${config.fontProfiles.monospace.family}:size=10;3";
  #     font-1 = "${config.fontProfiles.regular.family}:style=Bold:size=10;3";
  #     modules-left = "distro-icon dulS ddrT i3 dulT";
  #     modules-center = "title";
  #     modules-right = "durT audio ddlT wireless-network date";
  #     locale = "en_US.UTF-8";
  #   };
  #   "bar/bottom" = {
  #     bottom = true;
  #     fixed-center = true;
  #     width = "100%";
  #     height = 14;
  #     offset-x = "1%";
  #     background = "${colors.base00}";
  #     foreground = "${colors.base05}";
  #     radius-top = 0;
  #     tray-position = "none";
  #     # tray-detached = false;
  #     # tray-maxsize = 15;
  #     # tray-background = primary;
  #     # tray-offset-x = - 19;
  #     # tray-offset-y = 0;
  #     # tray-padding = 5;
  #     # tray-scale = 1;
  #     padding = 0;
  #     font-0 = "${config.fontProfiles.monospace.family}:size=10;3";
  #     font-1 = "${config.fontProfiles.regular.family}:style=Bold:size=10;3";
  #     modules-left = "powermenu ddlS";
  #     modules-right = "ddrS cpu dulS ddrT memory dulT ddrP battery";
  #     locale = "en_US.UTF-8";
  #   };
  #   "settings" =
  #     {
  #       throttle-output = 5;
  #       throttle-output-for = 10;
  #       throttle-input-for = 30;
  #       screenchange-reload = true;
  #       compositing-background = "source";
  #       compositing-foreground = "over";
  #       compositing-overline = "over";
  #       comppositing-underline = "over";
  #       compositing-border = "over";
  #       pseudo-transparency = "false";
  #     };
  #   #--------------------MODULES--------------------"

  #   "module/audio" =
  #     {
  #       type = "internal/alsa";
  #       format-volume = "墳 <label-volume>";
  #       format-volume-padding = 1;
  #       format-volume-foreground = "${colors.base05}";
  #       format-volume-background = tertiary;
  #       label-volume = "%percentage%%";
  #       format-muted = "<label-muted>";
  #       format-muted-padding = 1;
  #       format-muted-foreground = "${colors.base05}";
  #       # format-muted-foreground = urgency;
  #       format-muted-background = tertiary;
  #       # format-muted-prefix = "婢 ";
  #       # format-muted-prefix-foreground = urgency;
  #       format-muted-overline = bg;
  #       label-muted = "婢";
  #       # label-muted = "VOL Muted";
  #     };
  #   "module/battery" =
  #     {
  #       poll-interval = 2;
  #       label-full = " 100%";
  #       format-full-padding = 1;
  #       format-full-foreground = secondary;
  #       format-full-background = "${colors.base05}";
  #       format-charging = " <animation-charging> <label-charging>";
  #       format-charging-padding = 1;
  #       format-charging-foreground = secondary;
  #       format-charging-background = "${colors.base05}";
  #       label-charging = "%percentage%% +%consumption%W";
  #       animation-charging-0 = "";
  #       animation-charging-1 = "";
  #       animation-charging-2 = "";
  #       animation-charging-3 = "";
  #       animation-charging-4 = "";
  #       animation-charging-framerate = 500;
  #       format-discharging = "<ramp-capacity> <label-discharging>";
  #       format-discharging-padding = 1;
  #       format-discharging-foreground = secondary;
  #       format-discharging-background = "${colors.base05}";
  #       label-discharging = "%percentage%% -%consumption%W";
  #       ramp-capacity-0 = "";
  #       ramp-capacity-0-foreground = urgency;
  #       ramp-capacity-1 = "";
  #       ramp-capacity-1-foreground = urgency;
  #       ramp-capacity-2 = "";
  #       ramp-capacity-3 = "";
  #       ramp-capacity-4 = "";
  #     };
  #   "module/cpu" =
  #     {
  #       type = "internal/cpu";
  #       interval = "0.5";
  #       format = " <label>";
  #       format-foreground = "${colors.base05}";
  #       format-background = "${colors.base00}";
  #       format-padding = 1;
  #       label = "CPU %percentage%%";
  #     };

  #   "module/i3" =
  #     {
  #       type = "internal/i3";
  #       pin-workspaces = false;
  #       strip-wsnumbers = true;
  #       format = "<label-state> <label-mode>";
  #       format-background = "${colors.base01}";
  #       ws-icon-0 = "1;";
  #       ws-icon-1 = "2;";
  #       ws-icon-2 = "3;﬏";
  #       ws-icon-3 = "4;";
  #       ws-icon-4 = "5;";
  #       ws-icon-5 = "6;";
  #       ws-icon-6 = "7;";
  #       ws-icon-7 = "8;";
  #       ws-icon-8 = "9;";
  #       ws-icon-9 = "10;";
  #       label-mode = "%mode%";
  #       label-mode-padding = 1;
  #       label-unfocused = "%icon%";
  #       label-unfocused-foreground = "${colors.base03}";
  #       label-unfocused-padding = 1;
  #       label-focused = "%index% %icon%";
  #       label-focused-font = 2;
  #       label-focused-foreground = "${colors.base05}";
  #       label-focused-padding = 1;
  #       label-visible = "%icon%";
  #       label-visible-padding = 1;
  #       label-urgent = "%index%";
  #       label-urgent-foreground = "${colors.base07}";
  #       label-urgent-padding = 1;
  #       label-separator = "";
  #     };
  #   "module/title" =
  #     {
  #       type = "internal/xwindow";
  #       format = "<label>";
  #       format-foreground = secondary;
  #       label = "%title%";
  #       label-maxlen = 70;
  #     };
  #   "module/memory" =
  #     {
  #       type = "internal/memory";
  #       interval = 3;
  #       format = " <label>";
  #       format-background = "${colors.base00}";
  #       format-foreground = "${colors.base03}";
  #       format-padding = 1;
  #       label = "RAM %percentage_used%%";
  #     };
  #   "module/network" =
  #     {
  #       type = "internal/network";
  #       interface = "enp3s0";
  #       interval = "1.0";
  #       accumulate-stats = true;
  #       unknown-as-up = true;
  #       format-connected = "<label-connected>";
  #       format-connected-background = "${colors.base00}";
  #       format-connected-underline = "${colors.base0B}";
  #       format-connected-overline = bg;
  #       format-connected-padding = 2;
  #       format-connected-margin = 0;
  #       format-disconnected = "<label-disconnected>";
  #       format-disconnected-background = "${colors.base00}";
  #       format-disconnected-underline = "${colors.base0B}";
  #       format-disconnected-overline = bg;
  #       format-disconnected-padding = 2;
  #       format-disconnected-margin = 0;
  #       label-connected = "D %downspeed:2% | U %upspeed:2%";
  #       label-disconnected = "DISCONNECTED";
  #     };
  #   "module/temperature" =
  #     {
  #       type = "internal/temperature";
  #       interval = "0.5";
  #       thermal-zone = 0;
  #       # TODO: Find a better way to fill that
  #       warn-temperature = 60;
  #       units = true;
  #       format = "<label>";
  #       format-background = "${colors.base00}";
  #       format-underline = "${colors.base0B}";
  #       format-overline = "${colors.base00}";
  #       format-padding = 2;
  #       format-margin = 0;
  #       format-warn = "<label-warn>";
  #       format-warn-background = "${colors.base00}";
  #       format-warn-underline = "${colors.base0B}";
  #       format-warn-overline = bg;
  #       format-warn-padding = 2;
  #       format-warn-margin = 0;
  #       label = "TEMP %temperature-c%";
  #       label-warn = "TEMP %temperature-c%";
  #       label-warn-foreground = "#f00";
  #     };
  #   "module/powermenu" =
  #     {
  #       type = "custom/menu";
  #       expand-right = true;
  #       format = "<label-toggle> <menu>";
  #       format-background = "${colors.base00}";
  #       format-padding = 1;
  #       label-open = "";
  #       label-close = "";
  #       label-separator = "  ";
  #       menu-0-0 = " Suspend";
  #       menu-0-0-exec = "systemctl suspend";
  #       menu-0-1 = " Reboot";
  #       menu-0-1-exec = "v";
  #       menu-0-2 = " Shutdown";
  #       menu-0-2-exec = "systemctl poweroff";
  #     };
  #   "module/wireless-network" =
  #     {
  #       type = "internal/network";
  #       interface = "wlp1s0";
  #       interval = 1;
  #       accumulate-stats = true;
  #       format-connected = "<label-connected>";
  #       label-connected = "%ifname%";
  #       label-connected-background = "${colors.base00}";
  #       label-connected-foreground = "${colors.base03}";
  #       label-connected-padding = 1;
  #       format-disconnected = "<label-disconnected>";
  #       label-disconnected = "offline";
  #       label-disconnected-background = "${colors.base00}";
  #       label-disconnected-foreground = "${colors.base03}";
  #       label-disconnected-padding = 1;
  #     };
  #   #--------------------SOLID TRANSITIONS--------------------#
  #   "module/dsPT" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = "${colors.base00}";
  #       content-foreground = tertiary;
  #     };
  #   "module/dsTS" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = "${colors.base00}";
  #       content-foreground = secondary;
  #     };
  #   "module/dsST" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = "${colors.base00}";
  #       content-foreground = tertiary;
  #     };
  #   "module/daPT" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = "${colors.base00}";
  #       content-foreground = tertiary;
  #     };
  #   "module/daTP" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = tertiary;
  #       content-foreground = "${colors.base00}";
  #     };
  #   "module/daST" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = secondary;
  #       content-foreground = "${colors.base00}";
  #     };
  #   "module/daTS" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = secondary;
  #       content-foreground = "${colors.base00}";
  #     };
  #   "module/daSP" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-background = secondary;
  #       content-foreground = "${colors.base00}";
  #     };
  #   #--------------------GAPS TRANSITIONS--------------------#
  #   "module/dulT" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = tertiary;
  #       content-background = "${colors.base00}";
  #     };
  #   "module/ddrT" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = tertiary;
  #       content-background = "${colors.base00}";
  #     };
  #   "module/ddlT" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = tertiary;
  #       content-background = bg;
  #     };
  #   "module/durT" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = tertiary;
  #       content-background = bg;
  #     };
  #   "module/ddlP" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = primary;
  #       content-background = bg;
  #     };
  #   "module/durP" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = primary;
  #       content-background = bg;
  #     };
  #   "module/dulP" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = primary;
  #       content-background = bg;
  #     };
  #   "module/ddrP" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = primary;
  #       content-background = bg;
  #     };
  #   "module/dulS" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = secondary;
  #       content-background = bg;
  #     };
  #   "module/ddlS" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = secondary;
  #       content-background = bg;
  #     };
  #   "module/durS" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = secondary;
  #       content-background = bg;
  #     };
  #   "module/ddrS" =
  #     {
  #       type = "custom/text";
  #       content = "";
  #       content-foreground = secondary;
  #       content-background = bg;
  #     };
  # };

  # xdg.configFile."polybar/colors.ini".source = ./colors.ini;

  xdg.configFile."polybar/scripts" = lib.mkIf config.services.polybar.enable { source = ./scripts; recursive = true; };
}
