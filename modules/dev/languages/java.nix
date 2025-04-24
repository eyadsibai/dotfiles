{ lib, config, pkgs, ... }:

let
  cfg = config.dev.languages.java;
in
{
  options.dev.languages.java = {
    enable = lib.mkEnableOption "Java Development Kit (JDK)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jetbrains.jdk
    ];
  };
}
