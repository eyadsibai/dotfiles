{ inputs
, config
, lib
, pkgs
, hostname
, username
, ...
}:
{
  imports =
    [
      ../.
      ./homebrew.nix
    ];

  networking = {
    computerName = hostname;
    hostName = hostname;
    localHostName = hostname;
  };

}
