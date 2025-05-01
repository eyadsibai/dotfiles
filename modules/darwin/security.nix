{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.security;
in
{
  options.darwin.security = {
    enableTouchIdSudo = lib.mkEnableOption "Enable sudo authentication with Touch ID";
    # Could add an option for the NOPASSWD rule if desired
  };

  # Define config unconditionally
  config = {
    # Use lib.mkIf for non-list attributes
    security.pam.services.sudo_local.touchIdAuth = lib.mkIf (cfg.enableTouchIdSudo && pkgs.stdenv.isDarwin) true;
    # Consider if this NOPASSWD rule is truly desired - it's a security risk
    # security.sudo.extraConfig = lib.mkIf (cfg.enableTouchIdSudo && pkgs.stdenv.isDarwin) "%admin ALL = (ALL) NOPASSWD: ALL";
  };
}
