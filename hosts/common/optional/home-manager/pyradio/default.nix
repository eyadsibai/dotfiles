{ pkgs, ... }:
{
  home.packages = [ pkgs.pyradio ];
  xdg.configFile."pyradio/config".source = ./config;
  xdg.configFile."pyradio/stations.csv".source = ./stations.csv;
}
