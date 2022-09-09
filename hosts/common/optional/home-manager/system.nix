{ pkgs
, config
, hostname
, ...
}: {
  home.packages = with pkgs; [
    dive
    glances
    killall
    xorg.xkill
    ranger
  ];
}
