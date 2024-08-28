{
  username,
  hostname,
  ...
} @ args:
#############################################################
#
#  Host & Users configuration
#
#############################################################
{
  networking.hostName = hostname;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."${username}" = {
      isNormalUser = true;
    description = username;
    extraGroups = [ "networkmanager" "wheel" ];
 
  };

  nix.settings.trusted-users = [username "root"];
}
