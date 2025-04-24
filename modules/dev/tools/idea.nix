{ lib, config, pkgs, ... }:

let
  cfg = config.dev.tools.idea;
in
{
  options.dev.tools.idea = {
    enable = lib.mkEnableOption "IntelliJ IDEA Ultimate";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      jetbrains.idea-ultimate
    ];
  };
}
