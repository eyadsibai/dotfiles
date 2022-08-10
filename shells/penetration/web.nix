{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell {

  buildInputs = [
    brakeman
    burpsuite
    cameradar
    cariddi
    chopchop
    commix
    corsair-scan
    crlfsuite
    dalfox
    dirb
    dismap
    dontgo403
    galer
    gau
    gobuster
    gospider
    gotestwaf
    gowitness
    graphqlmap
    graphw00f
    hakrawler
    hey
    httpx
    hyperpotamus
    jaeles
    jsubfinder
    jwt-hack
    kiterunner
    mitmproxy2swagger
    monsoon
    nikto
    ntlmrecon
    photon
    slowlorust
    snallygaster
    subjs
    swaggerhole
    uddup
    urlhunter
    wad
    webanalyze
    whatweb
    wprecon
    wpscan
    wfuzz
    wuzz
    zap
  ];
  shellHook = "";
}
