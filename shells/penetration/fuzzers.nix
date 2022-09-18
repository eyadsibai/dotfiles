# Fuzzing tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    afl
    aflplusplus
    feroxbuster
    ffuf
    honggfuzz
    radamsa
    regexploit
    ssdeep
    wfuzz
    zzuf
  ];
  shellHook = "";
}
