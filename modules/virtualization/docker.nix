{ lib, config, pkgs, username, ... }:

let
  cfg = config.virtualization.docker;
in
{
  options.virtualization.docker = {
    enable = lib.mkEnableOption "Docker containerization";
    rootless.enable = lib.mkEnableOption "Enable rootless Docker";
    nvidiaToolkit.enable = lib.mkEnableOption "Enable Nvidia container toolkit";
  };

  config = lib.mkIf cfg.enable {
    virtualisation.docker.enable = true;

    # Add user to docker group (for non-rootless)
    users.extraGroups.docker.members = lib.mkIf (!cfg.rootless.enable) [ username ];

    # Rootless Docker config
    virtualisation.docker.rootless = lib.mkIf cfg.rootless.enable {
      enable = true;
      setSocketVariable = true;
    };

    # Nvidia container toolkit
    hardware.nvidia-container-toolkit.enable = lib.mkIf cfg.nvidiaToolkit.enable true;

    # Install docker-compose package
    environment.systemPackages = with pkgs; [
      docker-compose
    ];
  };
}
