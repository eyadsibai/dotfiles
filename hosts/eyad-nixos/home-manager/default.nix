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
  palette = config.lib.stylix.colors;
in
{ }
