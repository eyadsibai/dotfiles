{ lib, config, ... }:

let
  cfg = config.services.tika;
in
{
  options.services.tika = {
    enable = lib.mkEnableOption "Apache Tika service";
  };

  config = lib.mkIf cfg.enable {
    services.tika.enable = true;
  };
}
