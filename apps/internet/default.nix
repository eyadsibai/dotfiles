{ pkgs, ... }: {
  imports = [ ./browsers.nix ./email_cal_rss.nix ./social.nix ];
}
