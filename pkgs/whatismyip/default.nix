# {pkgs, stdenv, ...}:
# let
#   # The ${...} is for string interpolation
#   # The '' quotes are used for multi-line strings
#   simplePackage = pkgs.writeShellScriptBin "whatsmyip" ''
#     ${pkgs.curl}/bin/curl http://httpbin.org/get \
#       | ${pkgs.jq}/bin/jq --raw-output .origin
#   '';
# in
# stdenv.mkDerivation {
#   name = "whatsmyip";
#   buildInputs = [ simplePackage ];
#   dontUnpack = true;
# }


{writeShellApplication, curl, jq}: writeShellApplication {
  name = "whatismyip";

  runtimeInputs = [ curl jq ];

  text = ''
    curl -s http://httpbin.org/get \
     | jq --raw-output .origin
  '';
}
