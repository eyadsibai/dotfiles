# Bluetooth tools
{ pkgs, ... }:
with pkgs;
mkShell {

  buildInputs = [
    bluez
    bluewalker
    bleak
    redfang
    ubertooth
  ];
  shellHook = "";

}
