{
  config,
  lib,
  username,
  ...
}:
{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "wheel"
    ]
    ++ lib.optional config.networking.networkmanager.enable "networkmanager"
    ++ lib.optional config.virtualisation.docker.enable "docker"
    ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";
    openssh.authorizedKeys.keyFiles = [ ./authorized-keys ];
  };
}
