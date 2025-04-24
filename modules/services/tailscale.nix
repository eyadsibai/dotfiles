{ lib, config, ... }:

let
  cfg = config.services.tailscale;
in
{
  options.services.tailscale = {
    enable = lib.mkEnableOption "Tailscale VPN service";
    # Add more options for flags if needed, or keep them hardcoded for now
  };

  config = lib.mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      useRoutingFeatures = "both";
      extraSetFlags = [
        "--advertise-routes=192.168.50.0/24" # allow routing traffic from other nodes to lan
        "--accept-routes" # route traffic to other lan
        "--advertise-exit-node" # allow allow routing traffic through this node
      ];
    };
  };
}
