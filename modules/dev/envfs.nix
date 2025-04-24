{ lib, config, ... }:

let
  cfg = config.dev.envfs;
in
{
  options.dev.envfs = {
    enable = lib.mkEnableOption "envfs service";
  };

  config = lib.mkIf cfg.enable {
    services.envfs.enable = true;
  };
}
