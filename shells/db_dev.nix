{ pkgs ? import <nixpkgs> { } }:
pkgs.mkShell
{
  buildInputs = with pkgs; [
    pgcli
    # modern postgres client
    mycli
    iredis
    usql
  ];
}
