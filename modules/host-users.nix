{ username
, hostname
, lib
, pkgs
, ...
} @ args:
#############################################################
#
#  Host & Users configuration (Shared Linux/Darwin)
#
#############################################################
{
  # Common hostname setting
  networking.hostName = hostname;

  # Darwin specific hostname settings
  networking.computerName = lib.mkIf pkgs.stdenv.isDarwin hostname;
  system.defaults.smb.NetBIOSName = lib.mkIf pkgs.stdenv.isDarwin hostname;

  # Define a user account.
  users.users."${username}" = {
    description = username;
    # Darwin specific user settings (Home directory is set by Home Manager)
    # home = lib.mkIf pkgs.stdenv.isDarwin "/Users/${username}";
  } // lib.optionalAttrs pkgs.stdenv.isLinux {
    isNormalUser = true;
    extraGroups = [ "networkmanager" "wheel" ];
  };

  # Trusted users for Nix daemon
  nix.settings.trusted-users = [ username ] ++ (lib.optionals pkgs.stdenv.isLinux [ "root" ]); # Use optionals for list concat
}
