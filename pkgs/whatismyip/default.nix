{pkgs, ...}:

let
  # The ${...} is for string interpolation
  # The '' quotes are used for multi-line strings
  simplePackage = pkgs.writeShellScriptBin "whatIsMyIp" ''
    ${pkgs.curl}/bin/curl http://httpbin.org/get \
      | ${pkgs.jq}/bin/jq --raw-output .origin
  '';
in
stdenv.mkDerivation rec {
  name = "whatsmyip";

  buildInputs = [ simplePackage ];
}
