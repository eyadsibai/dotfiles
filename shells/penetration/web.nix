{ pkgs, ... }:
with pkgs;
mkShell {

  buildInputs = [
    brakeman
    cameradar
    cariddi
    chopchop
    commix
    corsair-scan
    crlfsuite
    dalfox
    dismap
    dontgo403
    galer
    gau
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
    wad
    webanalyze
    whatweb
    wprecon
    wpscan
    wuzz
  ];
  shellHook = "";
}
    