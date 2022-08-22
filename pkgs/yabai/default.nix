{ pkgs, ... }:
pkgs.stdenvNoCC.mkDerivation rec {
  name = "yabai";
  version = "4.0.1";
  src = pkgs.fetchurl {
    url = "https://github.com/koekeishiya/yabai/releases/download/v${version}/yabai-v${version}.tar.gz";
    # sha256 = pkgs.lib.fakeSha256;
    sha256 = "sha256-UFtPBftcBytzvrELOjE4vPCKc3CCaA4bpqusok5sUMU=";
  };

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p $out
    cp -ar ./* $out
    chmod +x $out/bin/yabai
  '';
}
