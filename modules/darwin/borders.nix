{ lib, config, pkgs, username, ... }:

let
  cfg = config.darwin.borders;
in
{
  options.darwin.borders = {
    enable = lib.mkEnableOption "Window borders (e.g., yabai-borders)";
  };

  # Define config unconditionally
  config = {
    # Use lib.mkIf for non-list attributes
    home-manager.users = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
      "${username}" = {
        # Assuming 'borders' is the package name, adjust if needed
        # Add package if not managed elsewhere (e.g., by a yabai module)
        # home.packages = with pkgs; [ borders ];

        # Link the configuration file
        home.file.".config/borders/bordersrc" = {
          source = ../../config/darwin/bordersrc;
          # Ensure script is executable
          executable = true;
        };
      };
    };

    # Potentially start borders service if needed via launchd
    # services.borders = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    #   enable = true;
    #   package = pkgs.borders;
    # };
  };
}
