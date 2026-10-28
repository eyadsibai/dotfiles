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
      "networkmanager"
      "wheel"
    ]
    ++ lib.optional config.virtualisation.docker.enable "docker"
    ++ lib.optional config.virtualisation.libvirtd.enable "libvirtd";
    openssh.authorizedKeys.keyFiles = [ ./authorized-keys ];
  };

  nix.settings.trusted-users = [
    username
    "root"
  ];
}
