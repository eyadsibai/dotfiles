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
    # Linux specific user settings
    isNormalUser = lib.mkIf pkgs.stdenv.isLinux true;
    extraGroups = lib.mkIf pkgs.stdenv.isLinux [ "networkmanager" "wheel" ];
    # Darwin specific user settings (Home directory is set by Home Manager)
    # home = lib.mkIf pkgs.stdenv.isDarwin "/Users/${username}";
  };

  # Trusted users for Nix daemon
  nix.settings.trusted-users = [ username ] ++ (lib.mkIf pkgs.stdenv.isLinux [ "root" ]);
}
