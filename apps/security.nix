{ pkgs, ... }: { home.packages = with pkgs; [ socialscan sherlock snscrape ]; }
