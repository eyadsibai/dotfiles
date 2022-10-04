# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ inputs, pkgs, ... }: {
  flakify = pkgs.callPackage ./flakify { };
  linkhandler = pkgs.callPackage ./linkhandler { };
  apple-color-emoji = pkgs.callPackage ./apple-color-emoji { };

  kepler = pkgs.callPackage ./kepler { };
  sherlock = pkgs.callPackage ./sherlock { };
  shellcolord = pkgs.callPackage ./shellcolord { };
  wallpapers = pkgs.callPackage ./wallpapers { };
  icomoon-feather-ttf = pkgs.callPackage ./icomoon-feather-ttf { };
  whatsie = pkgs.libsForQt514.callPackage ./whatsie { };
  latest-caprine = pkgs.callPackage (inputs.nixpkgs + "/pkgs/applications/networking/instant-messengers/caprine-bin/build-from-appimage.nix")
    {

      pname = "caprine";
      version = "2.56.1";
      sha256 = "sha256-NhHToaacje4TtZkW3TxtyGzH/uKGCWgGdtvI9oSTJF4=";
    };
  ## ML Libraries
  rgf = pkgs.callPackage ./rgf { };
  fast-rgf = pkgs.callPackage ./fast-rgf { };
  libfm = pkgs.callPackage ./libfm { };
}
