{ pkgs
, ...
}:
{
  home.packages =
    with pkgs; [ haskellPackages.network-manager-tui alsaUtils lxappearance ];

}
