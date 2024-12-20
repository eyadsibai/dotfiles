{ inputs
, lib
, config
, pkgs
, hostname
, username
, ...
}:
let
  homeConfig = config.home-manager.users.${username};
  palette = config.lib.stylix.colors;

in
{
  stylix =
    {
      enable = true;
      autoEnable = true;
      image = ./x.jpeg;
      polarity = "dark";
      fonts = {
        serif = {
          package = pkgs.fira;
          name = "Fira Sans";
        };


        monospace = {
          package = pkgs.nerd-fonts.fira-code;

          name = "FiraCode Nerd Font Mono";
        };

        sansSerif = {
          name = "Fira Sans";
          package = pkgs.fira;
        };

        emoji = {
          package = pkgs.noto-fonts-emoji;
          name = "Noto Color Emoji";
        };
        sizes = {
          applications = 8;
          terminal = 10;
          desktop = 8;
          popups = 8;
        };
      };

      base16Scheme = "${pkgs.base16-schemes}/share/themes/tokyo-night-storm.yaml";
      cursor.package = pkgs.bibata-cursors;
      cursor.name = "Bibata-Modern-Ice";
      cursor.size = 16;
      opacity = {
        applications = 0.95;
        terminal = 0.95;
        desktop = 0.95;
        popups = 0.95;
      };

    };
}
