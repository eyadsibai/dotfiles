# When you add custom packages, list them here
# These are similar to nixpkgs packages
{ inputs
, pkgs ? (import ../nixpkgs.nix) { }
, ...
}: {
  flakify = pkgs.callPackage ./flakify { };
  linkhandler = pkgs.callPackage ./linkhandler { };
  apple-color-emoji = pkgs.callPackage ./apple-color-emoji { };

  kepler = pkgs.callPackage ./kepler { };
  sherlock = pkgs.callPackage ./sherlock { };
  shellcolord = pkgs.callPackage ./shellcolord { };
  wallpapers = pkgs.callPackage ./wallpapers { };
  icomoon-feather-ttf = pkgs.callPackage ./icomoon-feather-ttf { };
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
  # TODO add libFFM
  # https://www.csie.ntu.edu.tw/~cjlin/libffm/
  # TODO add FTRL implementations
  # TODO
}
