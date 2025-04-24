{ lib, config, ... }:

let
  cfg = config.services.n8n;
in
{
  options.services.n8n = {
    enable = lib.mkEnableOption "n8n workflow automation tool";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for n8n.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.n8n = {
      enable = true;
      openFirewall = cfg.openFirewall;
    };
  };
}
