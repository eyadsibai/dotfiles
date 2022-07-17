{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    initExtra = "neofetch";

  };
}
