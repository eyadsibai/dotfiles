{ config
, pkgs
, inputs
, ...
}:
# let
#   inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
# in
# rec
{
  gtk = {
    enable = true;
    # font = {
    #   name = config.stylix.fonts.sansSerif.name;
    #   size = 12;
    # };
    # theme = {
    #   # name = "${config.colorscheme.slug}";
    #   # package = gtkThemeFromScheme { scheme = config.colorscheme; };
    # };
    # iconTheme = {
    #   name = "Papirus";
    #   package = pkgs.papirus-icon-theme;
    # };
    # gtk3.extraConfig = {
    #   gtk-application-prefer-dark-theme = true;
    # };
    # gtk4.extraConfig = {
    #   gtk-application-prefer-dark-theme = true;
    # };
  };

  services.xsettingsd = {
    enable = true;
    settings = {
      # "Net/ThemeName" = "${gtk.theme.name}";
      # "Net/IconThemeName" = "${gtk.iconTheme.name}";
    };
  };
}
