{ pkgs
, config
, ...
}: {

  programs.rofi = {
    enable = true;
    plugins = with pkgs; [ rofi-calc rofi-emoji ];
    terminal = "${config.home.preferredApps.terminal.cmd}";
    extraConfig = {
      modi = "window,drun,ssh,combi";
      combi-modi = "run,drun,window,emoji,ssh";
      show-icons = true;
      display-drun = "";
      display-ssh = "";
      display-window = "";
      display-combi = "";
      hide-scrollbar = true;
      fake-transparency = true;
      run-shell-command = "${(config.home.preferredApps.terminal.cmd-spawn "{cmd}")}";
    };
    theme =
      let
        inherit (config.lib.formats.rasi) mkLiteral;
        inherit (config.colorscheme) colors;
      in
      {
        "*" = {
          red = mkLiteral "#${colors.base08}";
          blue = mkLiteral "#${colors.base0D}";
          lightfg = mkLiteral "#${colors.base06}";
          lightbg = mkLiteral "#${colors.base01}";
          foreground = mkLiteral "#${colors.base05}";
          background = mkLiteral "#${colors.base00}";
          background-color = mkLiteral "#${colors.base00}";
          separatorcolor = mkLiteral "@foreground";
          border-color = mkLiteral "@foreground";
          selected-normal-foreground = mkLiteral "@lightbg";
          selected-normal-background = mkLiteral "@lightfg";
          selected-active-foreground = mkLiteral "@background";
          selected-active-background = mkLiteral "@blue";
          selected-urgent-foreground = mkLiteral "@background";
          selected-urgent-background = mkLiteral "@red";
          normal-foreground = mkLiteral "@foreground";
          normal-background = mkLiteral "@background";
          active-foreground = mkLiteral "@blue";
          active-background = mkLiteral "@background";
          urgent-foreground = mkLiteral "@red";
          urgent-background = mkLiteral "@background";
          alternate-normal-foreground = mkLiteral "@foreground";
          alternate-normal-background = mkLiteral "@lightbg";
          alternate-active-foreground = mkLiteral "@blue";
          alternate-active-background = mkLiteral "@lightbg";
          alternate-urgent-foreground = mkLiteral "@red";
          alternate-urgent-background = mkLiteral "@lightbg";
        };

        "window" = {
          background-color = mkLiteral "@background";
          border = 1;
          padding = 5;
        };
        "mainbox" = {
          border = 0;
          padding = 0;
        };
        "message" = {
          border = mkLiteral "1px dash 0px 0px";
          border-color = mkLiteral "@separatorcolor";
          padding = mkLiteral "1px";
        };
        "textbox" = {
          text-color = mkLiteral "@foreground";
        };
        "listview" = {
          fixed-height = 0;
          border = mkLiteral "2px dash 0px 0px";
          border-color = mkLiteral "@separatorcolor";
          spacing = mkLiteral "2px";
          scrollbar = true;
          padding = mkLiteral "2px 0px 0px";
        };
        "element-text, element-icon" = {
          background-color = mkLiteral "inherit";
          text-color = mkLiteral "inherit";
        };
        "element" = {
          border = 0;
          padding = mkLiteral "1px";
        };
        "element normal.normal" = {
          background-color = mkLiteral "@normal-background";
          text-color = mkLiteral "@normal-foreground";
        };
        "element normal.urgent" = {
          background-color = mkLiteral "@urgent-background";
          text-color = mkLiteral "@urgent-foreground";
        };
        "element normal.active" = {
          background-color = mkLiteral "@active-background";
          text-color = mkLiteral "@active-foreground";
        };
        "element selected.normal" = {
          background-color = mkLiteral "@selected-normal-background";
          text-color = mkLiteral "@selected-normal-foreground";
        };
        "element selected.urgent" = {
          background-color = mkLiteral "@selected-urgent-background";
          text-color = mkLiteral "@selected-urgent-foreground";
        };
        "element selected.active" = {
          background-color = mkLiteral "@selected-active-background";
          text-color = mkLiteral "@selected-active-foreground";
        };
        "element alternate.normal" = {
          background-color = mkLiteral "@alternate-normal-background";
          text-color = mkLiteral "@alternate-normal-foreground";
        };
        "element alternate.urgent" = {
          background-color = mkLiteral "@alternate-urgent-background";
          text-color = mkLiteral "@alternate-urgent-foreground";
        };
        "element alternate.active" = {
          background-color = mkLiteral "@alternate-active-background";
          text-color = mkLiteral "@alternate-active-foreground";
        };
        "scrollbar" = {
          width = mkLiteral "4px";
          border = 0;
          handle-color = mkLiteral "@normal-foreground";
          handle-width = mkLiteral "8px";
          padding = 0;
        };
        "sidebar" = {
          border = mkLiteral "2px dash 0px 0px";
          border-color = mkLiteral "@separatorcolor";
        };
        "button" = {
          spacing = 0;
          text-color = mkLiteral "@normal-foreground";
        };
        "button selected" = {
          background-color = mkLiteral "@selected-normal-background";
          text-color = mkLiteral "@selected-normal-foreground";
        };
        "inputbar" = {
          spacing = mkLiteral "0px";
          text-color = mkLiteral "@normal-foreground";
          padding = mkLiteral "1px";
          children = mkLiteral "[ prompt,textbox-prompt-colon,entry,case-indicator ]";
        };
        "case-indicator" = {
          spacing = 0;
          text-color = mkLiteral "@normal-foreground";
        };
        "entry" = {
          spacing = 0;
          text-color = mkLiteral "@normal-foreground";
        };
        "prompt" = {
          spacing = 0;
          text-color = mkLiteral "@normal-foreground";
        };
        "textbox-prompt-colon" = {
          expand = false;
          # str = "=";
          margin = mkLiteral "0px 0.3000em 0.0000em 0.0000em";
          text-color = mkLiteral "inherit";
        };
      };
  };

  home.packages = [ pkgs.rofi-rbw ];
}
