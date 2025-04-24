{ lib, config, pkgs, ... }:

let
  cfg = config.dev.tools.devbox;
in
{
  options.dev.tools.devbox = {
    enable = lib.mkEnableOption "Devbox";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      devbox
    ];
  };
}
