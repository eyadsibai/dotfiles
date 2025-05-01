{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.tools.nix;
in
{
  options.dev.tools.nix = {
    enable = lib.mkEnableOption "Nix development tools (nixd, nil)";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        home.packages = with pkgs; [
          nixd
          nil
        ];
      };
    };
  };
}
