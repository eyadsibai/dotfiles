{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell {

  buildInputs = [
    anevicon
    dhcpdump
    dnstop
    driftnet
    dsniff
    goreplay
    httpdump
    junkie
    netsniff-ng
    ngrep
    secrets-extractor
    sniffglue
    tcpdump
    tcpflow
    tcpreplay
    termshark
    wireshark
    wireshark-cli
    zeek
  ];
  shellHook = "";

}
