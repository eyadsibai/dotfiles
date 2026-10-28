{ username, ... }:
{
  users.users.${username} = {
    isNormalUser = true;
    description = username;
    extraGroups = [
      "networkmanager"
      "wheel"
      "docker"
      "libvirtd"
    ];
    openssh.authorizedKeys.keyFiles = [ ./authorized-keys ];
  };

  nix.settings.trusted-users = [
    username
    "root"
  ];
}
