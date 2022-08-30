{ pkgs
, config
, hostname
, inputs
, outputs
, ...

}:
let systemConfig = outputs.nixosConfigurations.${hostname}.config;
in
{
  imports = [ ../. ];
  home.packages =
    with pkgs;
    (lib.optionals (systemConfig.virtualisation.docker.enable or systemConfig.virtualisation.podman.enable)
      [ lazydocker ])
  ;

}
