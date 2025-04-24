{ lib, config, ... }:

let
  cfg = config.security.firewall;
in
{
  options.security.firewall = {
    enable = lib.mkEnableOption "NixOS Firewall";
    extraAllowedTCPPorts = lib.mkOption {
      type = with lib.types; listOf port;
      default = [];
      description = "Extra TCP ports to allow through the firewall, not managed by specific service modules.";
    };
    extraAllowedUDPPorts = lib.mkOption {
      type = with lib.types; listOf port;
      default = [];
      description = "Extra UDP ports to allow through the firewall, not managed by specific service modules.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.enable = true;
    # Note: allowedTCPPorts/allowedUDPPorts are merged across modules.
    # Service modules (like xrdp, openssh) should declare their own ports.
    # These options are for ports *not* associated with a specific service module.
    networking.firewall.allowedTCPPorts = cfg.extraAllowedTCPPorts;
    networking.firewall.allowedUDPPorts = cfg.extraAllowedUDPPorts;
  };
}
