{ inputs
, lib
, pkgs
, ...
}:
let
  secrets = import ../../../secrets;
  common = ../../../common;
in
{
  # inherit secrets;
  imports = [
    ../../../common/home-manager/git
  ];


  home.packages =
    with pkgs;
    [

    ];
  home.enableNixpkgsReleaseCheck = true;


  # programs.gpg.enable = true;

  news.display = "silent";
  home.stateVersion = "22.05";

}
