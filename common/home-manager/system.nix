{ pkgs
, config
, ...

}:
# let systemConfig = outputs.nixosConfigurations."eyad-nixos".config;
# in
{
  home.packages =
    with pkgs;
    [
      dive
      # explore docker layers
      glances
      killall
      xorg.xkill
      # kill processes by name
      ranger
      # terminal file explorer
      lazydocker
    ]
    # ++ (lib.optionals (config.virtualisation.docker.enable or config.virtualisation.podman.enable)
    #[ lazydocker ])
  ;

}
