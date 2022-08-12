{ pkgs ? import <nixpkgs> { }
, ...
}:
with pkgs;
mkShell
  {
    buildInputs = [
      authoscope
      bruteforce-luks
      brutespray
      crunch
      chntpw
      crowbar
      hashcat
      hashcat-utils
      hcxtools
      hashdeep
      john
      medusa
      nasty
      ncrack
      nth
      phrasendrescher
      # patator
      ( thc-hydra.override { withGUI = true; } )
      truecrack
    ];
    shellHook = "";
  }
