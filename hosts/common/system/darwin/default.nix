{ inputs
, config
, lib
, pkgs
, hostname
, user
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
