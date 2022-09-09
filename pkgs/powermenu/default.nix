{ writeShellApplication
, curl
, jq
,
}:
writeShellApplication {
  name = "whatismyip";

  runtimeInputs = [ curl jq ];

  text = ''
    curl -s http://httpbin.org/get \
     | jq --raw-output .origin
  '';
}
