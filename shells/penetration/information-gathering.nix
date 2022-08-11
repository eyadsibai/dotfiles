{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell {
  buildInputs = [
    cloudbrute
    maigret
    metabigor
    p0f
    sn0int
    socialscan
    theharvester
    urlhunter
    sherlock
  ];
  shellHook = "";
}
