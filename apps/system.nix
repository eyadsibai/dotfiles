{ pkgs, ... }: {

  home.packages = with pkgs; [
    bpytop
    bottom # alternative to htop & ytop (btm)
    dive # explore docker layers
    glances
    killall # kill processes by name
    ranger # terminal file explorer
    lazydocker
    cachix # nix caching
    gotop
    gtop

  ];

  programs.htop = {
    enable = true;
    settings = {
      sort_direction = true;
      sort_key = "PERCENT_CPU";
    };
  };
}
