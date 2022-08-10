# Terminal tools

{ pkgs ? import <nixpkgs> { }, ... }:

{
  environment.systemPackages = with pkgs; [
    cutecom
    minicom
    picocom
    socat
    x3270
  ];
}
