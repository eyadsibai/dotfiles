{ pkgs, ... }:
with pkgs;
mkShell {

  buildInputs = [
    arp-scan
    ipscan
    masscan
    naabu
    nmap
    sx-go
    rustscan
    zmap
  ];
  shellHook = "";
}
    