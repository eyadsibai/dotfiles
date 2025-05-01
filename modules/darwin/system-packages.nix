{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.system-packages;
in
{
  options.darwin.system-packages = {
    enable = lib.mkEnableOption "Install Darwin-specific system packages";
  };

  # Define config unconditionally
  config = {
    # Use lib.optionals for list assignments
    environment.systemPackages = lib.optionals (cfg.enable && pkgs.stdenv.isDarwin) (with pkgs; [
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
    ]);
  };
}
