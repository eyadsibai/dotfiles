# Tools to generate packets
{ pkgs ? import <nixpkgs> { }
, ...
}:
with pkgs;
mkShell
{
  buildInputs = [ boofuzz gping fping hping ostinato pktgen python3Packages.scapy ];
  shellHook = "";
}
