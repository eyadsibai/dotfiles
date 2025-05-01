{ lib, config, pkgs, ... }:

let
  cfg = config.dev.envfs;
in
{
  options.dev.envfs = {
    enable = lib.mkEnableOption "envfs service";
  };

  # Only apply on Linux systems
  config = lib.mkIf (cfg.enable && pkgs.stdenv.isLinux) {
    services.envfs.enable = true;
  };
  # Add additional configuration options for envfs if needed
}
