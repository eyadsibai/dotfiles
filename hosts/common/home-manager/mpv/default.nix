{ pkgs, ... }:
{
  programs.mpv = {
    enable = true;
    bindings = {
      l = "seek 5";
      h = "seek -5";
      k = "seek 60";
      S = "cycle sub";
    };
    scripts =
      with pkgs; [ mpvScripts.mpris mpvScripts.convert mpvScripts.cutter mpvScripts.autoload mpvScripts.thumbnail ];
  };
}
