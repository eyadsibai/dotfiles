# What Home Manager needs when it runs on its own, on a machine whose system another
# distribution owns: the Omarchy on Arch machines (arch.nix) and spark (hosts/spark).
{ pkgs, username, ... }:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true; # desktop entries and XDG paths for Nix's apps

  # The caches every machine uses, in ~/.config/nix/nix.conf. The daemon accepts
  # them from me because /etc/nix/nix.conf (arch/nix.conf, kept by scripts/arch-system)
  # makes me a trusted user. The package only checks the file at build time; the nix
  # that runs is the one the machine already has (pacman's, or the installer's).
  nix = {
    package = pkgs.nix;
    settings = { inherit (import ../common/caches.nix) substituters trusted-public-keys; };
  };

  home.packages = [ pkgs.nh ];
}
