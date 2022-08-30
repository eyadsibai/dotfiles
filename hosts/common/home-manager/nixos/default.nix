{ pkgs
, config
, hostname
, ...

}:
let systemConfig = outputs.nixosConfigurations.${hostname}.config;
in
{
  home.packages =
    with pkgs;
    (lib.optionals (config.virtualisation.docker.enable or config.virtualisation.podman.enable)
      [ lazydocker ])
  ;

}
