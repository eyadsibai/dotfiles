{ pkgs, ... }:
with pkgs;
mkShell {
  # https://github.com/NixOS/nixpkgs/issues/81418
  # https://github.com/fabaff/nix-security-box

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



    