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

}
