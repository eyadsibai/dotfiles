{ lib, config, pkgs, ... }:

let
  cfg = config.services.xrdp;
in
{
  options.services.xrdp = {
    enable = lib.mkEnableOption "XRDP remote desktop service";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for XRDP (TCP 3389).";
    };
    # defaultWindowManager option might be better set per-desktop environment
  };

  config = lib.mkIf cfg.enable {
    services.xrdp = {
      enable = true;
      openFirewall = cfg.openFirewall;
      # Note: The defaultWindowManager setting was previously in gnome.nix
      # It might be better to keep DE-specific settings like that in the DE module.
      # defaultWindowManager = if config.desktop.environment == "gnome" then "${pkgs.gnome-session}/bin/gnome-session" else null;
    };

    # Ensure the firewall port is open if requested (redundant if xrdp module handles it, but explicit)
    networking.firewall.allowedTCPPorts = lib.mkIf cfg.openFirewall [ 3389 ];
  };
}
