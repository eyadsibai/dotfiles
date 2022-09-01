{ pkgs, config, ... }:
{
  programs.rofi = {
    enable = true;
    plugins = with pkgs; [ rofi-calc rofi-emoji ];
    terminal = ${config.preferredApps.terminal.cmd};
    # theme = "${ pkgs.rofi }/share/rofi/themes/DarkBlue.rasi";

    theme =
      let
        # Use `mkLiteral` for string-like values that should show without
        # quotes, e.g.:
        # {
        #   foo = "abc"; => foo: "abc";
        #   bar = mkLiteral "abc"; => bar: abc;
        # };
        inherit (config.lib.formats.rasi) mkLiteral;
      in
      {
        "*" = {
          background-color = mkLiteral "#000000";
          foreground-color = mkLiteral "rgba ( 250, 251, 252, 100 % )";
          border-color = mkLiteral "#FFFFFF";
          width = 512;
        };

        "#inputbar" = {
          children = map mkLiteral [ "prompt" "entry" ];
        };

        "#textbox-prompt-colon" = {
          expand = false;
          str = ":";
          margin = mkLiteral "0px 0.3em 0em 0em";
          text-color = mkLiteral "@foreground-color";
        };
      }

      };

    home.packages = [ pkgs.rofi-rbw ];

  }
