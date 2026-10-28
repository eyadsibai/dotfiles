# Every Mac (eyad-m3, eyad-mac): same configuration, only the name differs
{ hostname, username, ... }:
{
  imports = [ ../../modules/darwin ];

  networking.hostName = hostname;
  networking.computerName = hostname;
  system.defaults.smb.NetBIOSName = hostname;

  users.users.${username}.home = "/Users/${username}";

  home-manager.users.${username}.home.stateVersion = "23.11";

  system.primaryUser = username;
  system.stateVersion = 5;
}
