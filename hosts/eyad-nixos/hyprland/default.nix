{ inputs, config, pkgs, username, lib, ... }:

{

  imports = [
    ./binds.nix
  ];

  nix.settings = {
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  programs.hyprland = {
    enable = true;
    # package = inputs.hyprland.packages.${pkgs.system}.hyprland;

  };

  environment.sessionVariables =
    {
      # if you cursor become invisible
      WLR_NO_HARDWARE_CURSORS = "1";

      # Hint electron apps to use native wayland
      NIXOS_OZONE_WL = "1";
    };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.greetd.tuigreet}/bin/tuigreet --time --cmd Hyprland";
        user = "greeter";
      };
    };
  };

  environment.systemPackages = with pkgs; [
    #    hyprpaper
    #    rofi-wayland
    waybar
    eww
    #    gnome-icon-theme

    libnotify

  ];

  home-manager.users.${username} = {
    wayland.windowManager.hyprland = {
      enable = true;
      systemd = {
        enable = true;
        # Same as default, but stop graphical-session too
        extraCommands = lib.mkBefore [
          "systemctl --user stop graphical-session.target"
          "systemctl --user start hyprland-session.target"
        ];
      };


      plugins = [
        # inputs.hyprland-plugins.packages."${pkgs.system}".borders-plus-plus
      ];
      settings = {


        general = {
          gaps_in = 15;
          gaps_out = 20;
          border_size = 2;
          # "col.active_border" = rgba config.colorscheme.colors.primary "aa";
          # "col.inactive_border" = rgba config.colorscheme.colors.surface "aa";
        };
        cursor.inactive_timeout = 4;
        group = {
          # "col.border_active" = rgba config.colorscheme.colors.primary "aa";
          # "col.border_inactive" = rgba config.colorscheme.colors.surface "aa";
          groupbar.font_size = 11;
        };
        binds = {
          movefocus_cycles_fullscreen = false;
        };

        # "plugin:borders-plus-plus" = {
        #   add_borders = 1;

        #   "col.border_1" = "rgb(ffffff)";
        #   "col.border_2" = "rgb(2222ff)";

        #   border_size_1 = 10;
        #   border_size_2 = -1;

        #   natural_rounding = "yes";
        # };
      };
    };

  };

}
