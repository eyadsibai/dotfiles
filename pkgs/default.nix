# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ pkgs
, ...
}:
{
  flakify = pkgs.callPackage ./flakify { };
  whatismyip = pkgs.callPackage ./whatismyip { };
  linkhandler = pkgs.callPackage ./linkhandler { };
  apple-color-emoji = pkgs.callPackage ./apple-color-emoji { };
  rgf = pkgs.callPackage ./rgf { };
  fast-rgf = pkgs.callPackage ./fast-rgf { };
  kepler = pkgs.callPackage ./kepler { };
  sherlock = pkgs.callPackage ./sherlock { };
  shellcolord = pkgs.callPackage ./shellcolord { };
  wallpapers = pkgs.callPackage ./wallpapers { };

}
