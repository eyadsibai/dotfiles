{ pkgs
, ...
}:
{
  home.packages =
    with pkgs; [ haskellPackages.network-manager-tui lxappearance ];

}
