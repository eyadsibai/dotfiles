{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.security;
in
{
  options.darwin.security = {
    enableTouchIdSudo = lib.mkEnableOption "Enable sudo authentication with Touch ID";
    # Could add an option for the NOPASSWD rule if desired
  };

  config = lib.mkIf (cfg.enableTouchIdSudo && pkgs.stdenv.isDarwin) {
    security.pam.services.sudo_local.touchIdAuth = true;
    # Consider if this NOPASSWD rule is truly desired - it's a security risk
    # security.sudo.extraConfig = "%admin ALL = (ALL) NOPASSWD: ALL";
  };
}
