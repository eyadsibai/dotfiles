{ inputs
, config
, lib
, pkgs
, hostname
, username
, ...
}: {
  imports = [
    ../.
    ./homebrew.nix
    ./system.nix
  ];

  networking = {
    computerName = hostname;
    hostName = hostname;
    localHostName = hostname;
  };
}
