# On Arch, pacman owns the programs and Home Manager only writes their config.
# Modules that take `package = null` get that; the ones that don't, but only run the
# program (never build with it), get this stand-in: a link to /usr/bin/<bin>, with
# nixpkgs' version so the modules' version checks still pick the right settings.
#
#   pacmanBin = import ./pacman-bin.nix pkgs;
#   programs.gh.package = lib.mkIf isArch (pacmanBin { bin = "gh"; from = pkgs.gh; });
pkgs:
{
  bin,
  from,
  extra ? "", # more commands for the build script, e.g. links to build-time helpers
}:
pkgs.runCommandLocal "${bin}-from-pacman-${from.version}"
  {
    inherit (from) version;
    meta.mainProgram = bin;
  }
  ''
    mkdir -p $out/bin
    ln -s /usr/bin/${bin} $out/bin/${bin}
    ${extra}
  ''
