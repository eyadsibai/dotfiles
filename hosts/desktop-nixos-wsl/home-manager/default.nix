{ inputs
, lib
, pkgs
, ...
}:
let
  secrets = import ../../../secrets;
in
{
  # inherit secrets;
  imports = [
  ];


  home.packages =
    with pkgs;
    [
    ];

  # programs.gpg.enable = true;

  # news.display = "silent";
  home.stateVersion = "22.05";

}
