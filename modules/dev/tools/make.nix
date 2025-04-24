{ lib, config, pkgs, ... }:

let
  cfg = config.dev.tools.make;
in
{
  options.dev.tools.make = {
    enable = lib.mkEnableOption "GNU Make";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      gnumake
    ];
  };
}
