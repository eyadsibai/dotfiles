{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.system-packages;
in
{
  options.darwin.system-packages = {
    enable = lib.mkEnableOption "Install Darwin-specific system packages";
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    environment.systemPackages = with pkgs; [
      # From Darwin darwin/apps.nix (excluding those handled by HM or elsewhere)
      statix
      wget
      curl
      httpie
      duf
      feh
      diff-pdf
      nb
      cointop
      colima
    ];
  };
}
