# Various tools
{ pkgs ? import <nixpkgs> { }
, ...
}:
{
  environment.systemPackages =
    with pkgs;
    [ badchars changetower deepsea doona honeytrap jwt-cli nmap-formatter pwntools python3Packages.pytenable ];
}
