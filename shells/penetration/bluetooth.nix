# Bluetooth tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [ bluez bluewalker bleak redfang ubertooth ];
  shellHook = "";
}
