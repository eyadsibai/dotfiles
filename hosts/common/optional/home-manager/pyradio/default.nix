{ pkgs, config, ... }: {
  home.packages = [ pkgs.pyradio ];
  xdg.configFile."pyradio/config" = lib.mkIf (builtins.elem pkgs.pyradio config.home.packages) {
    source = ./config;
  };
  xdg.configFile."pyradio/stations.csv" = lib.mkIf (builtins.elem pkgs.pyradio config.home.packages) {
    source = ./stations.csv;
  };
}
