{ pkgs
, ...
}:
{
  home.packages =
    with pkgs;
    [
      dive
      # explore docker layers
      glances
      killall
      xorg.xkill
      # kill processes by name
      ranger
      # terminal file explorer
      lazydocker
    ];
  programs.htop = {
    enable = true;
    settings = {
      sort_direction = true;
      sort_key = "PERCENT_CPU";
    };
  };
}
