{ lib
, stdenv
, fetchFromGitHub
, python3
, makeWrapper
,
}:
let
  pythonEnv = python3.withPackages (pkg:
    with pkg; [
      certifi
      colorama
      pandas
      pysocks
      requests
      requests-futures
      stem
      torrequest
    ]);
in
stdenv.mkDerivation {
  pname = "sherlock";
  version = "unstable-2022-08-25";

  # TODO override the current one instead

  src = fetchFromGitHub {
    owner = "sherlock-project";
    repo = "sherlock";
    rev = "0fd8853f44984e067dbcc3e6c7694204afddf01a";
    sha256 = "sha256-6jfkok8llp+liPnlZW7gIBoJEqOlGz8c3fGPWAZMQ1k=";
    # sha256 = lib.fakeSha256;
  };

  nativeBuildInputs = [ makeWrapper ];

  buildInputs = [ pythonEnv ];

  installPhase = ''
    mkdir -p $out/opt/
    cp -r sherlock $out/opt/
    makeWrapper ${pythonEnv}/bin/python3 $out/bin/sherlock \
      --add-flags "$out/opt/sherlock/sherlock.py"
  '';

  # All tests require access to the net

  meta = with lib; {
    description = "Hunt down social media accounts by username across social networks";
    homepage = "https://github.com/sherlock-project/sherlock";
    platforms = platforms.unix;
    licenses = licenses.mit;
    mainProgram = "sherlock";
  };
}
