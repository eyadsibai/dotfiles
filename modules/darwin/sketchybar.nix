{ lib, config, pkgs, username, ... }:

let
  cfg = config.darwin.sketchybar;
in
{
  options.darwin.sketchybar = {
    enable = lib.mkEnableOption "Sketchybar status bar";
  };

  # Define config unconditionally
  config = {
    # Use lib.mkIf for non-list attributes and lib.optionals for list assignments
    home-manager.users = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      "${username}" = {
        # Add sketchybar package and dependencies (jq used in media plugin)
        home.packages = with pkgs; [
          sketchybar
          jq
          # Add aerospace if needed for space integration
          # aerospace
        ];

        # Link the configuration directory
        home.file.".config/sketchybar" = {
          source = ../../config/darwin/sketchybar;
          recursive = true;
          # Ensure scripts are executable
          executable = true;
        };
      };
    };

    # Potentially start sketchybar service if needed via launchd
    # services.sketchybar = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    #   enable = true;
    #   package = pkgs.sketchybar;
    # };
    # Or handle startup via the sketchybarrc itself or another method
  };
}
