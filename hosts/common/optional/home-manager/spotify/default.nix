{ pkgs
, config
, inputs
, ...
}:
let
  palette = config.lib.stylix.colors;
  spicePkgs = inputs.spicetify-nix.packages.${pkgs.system}.default;
in
{
  home.packages = [
    # pkgs.spotify-player
    # pkgs.spotify-tui
    # pkgs.spotify
    # pkgs.spicetify-cli
  ];
  services.spotifyd.enable = false;
  programs.spotify-player = true;
  programs.spicetify = {
    enable = true;
    # specify that we want to use our custom colorscheme
    colorScheme = "custom";
    theme = spicePkgs.themes.text;

    # color definition for custom color scheme. (rosepine)
    customColorScheme = {
      text = "${palette.base05}";
      subtext = "${palette.base04}";
      sidebar-text = "${palette.base02}";
      main = "${palette.base00}"; # main_bg

      sidebar = "${palette.base00}"; # sidebar bg
      player = "${palette.base00}";
      card = "${palette.base01}";
      shadow = "${palette.base01}";
      selected-row = "${palette.base03}";
      button = "${palette.base08}";
      button-active = "${palette.base08}";
      button-disabled = "${palette.base04}";
      tab-active = "${palette.base08}";
      notification = "${palette.base02}";
      notification-error = "${palette.base03}";
      misc = "${palette.base02}";
    };
    enabledExtensions = with spicePkgs.extensions;
      [
        fullAppDisplay
        shuffle
        hidePodcasts
      ];
  };
}
