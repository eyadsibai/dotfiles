# Proxy tools for MitM scenarios
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    bettercap
    burpsuite
    ettercap
    mitmproxy
    mubeng
    proxify
    proxychains
    redsocks
    rshijack
    zap
  ];
  shellHook = "";
}
