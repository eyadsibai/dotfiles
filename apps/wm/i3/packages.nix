{pkgs, ...}:
{
  home.packages = [pkgs.networkmanager_dmenu pkgs.haskellPackages.network-manager-tui];
}