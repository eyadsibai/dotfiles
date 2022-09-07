{ pkgs, config, ... }:
let inherit (config.colorscheme) colors;
in {
  home.packages = [
    pkgs.spotify-tui
    # pkgs.spotify
    # pkgs.spicetify-cli
  ];
  services.spotifyd.enable = true;

  programs.spicetify = {
    enable = true;
    # specify that we want to use our custom colorscheme
    colorScheme = "custom";
    theme = "catppuccin-mocha";
    # color definition for custom color scheme. (rosepine)
    customColorScheme = {
      text = "${colors.base05}";
      subtext = "${colors.base04}";
      sidebar-text = "${colors.base02}";
      main = "${colors.base00}"; # main_bg

      sidebar = "${colors.base00}"; # sidebar bg
      player = "${colors.base00}";
      card = "${colors.base01}";
      shadow = "${colors.base01}";
      selected-row = "${colors.base03}";
      button = "${colors.base08}";
      button-active = "${colors.base08}";
      button-disabled = "${colors.base04}";
      tab-active = "${colors.base08}";
      notification = "${colors.base02}";
      notification-error = "${colors.base03}";
      misc = "${colors.base02}";
    };
    enabledExtensions = [
      "fullAppDisplay.js"
      "shuffle+.js"
      "hidePodcasts.js"
    ];
  };

}
