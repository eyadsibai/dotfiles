{ inputs
, lib
, pkgs
, config
, outputs
, hostname
, ...
}:
let
  sysConfig = outputs.nixosConfigurations.${hostname}.config;
  homeConfig = config;
  inherit (config.colorscheme) colors;
in
{ }
