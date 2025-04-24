{ lib, config, ... }:

let
  cfg = config.ai.ollama;
in
{
  options.ai.ollama = {
    enable = lib.mkEnableOption "Ollama service";
    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to open the firewall for Ollama.";
    };
    acceleration = lib.mkOption {
      type = lib.types.enum [ "cpu" "cuda" /* add others like rocm if needed */ ];
      default = "cpu";
      description = "Hardware acceleration to use for Ollama.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.ollama = {
      enable = true;
      openFirewall = cfg.openFirewall;
      acceleration = cfg.acceleration;
    };
  };
}
