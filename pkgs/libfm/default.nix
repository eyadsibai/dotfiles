{ fetchFromGitHub
, lib
, stdenv
, gcc
, gnumake
, pkg-config
,
}:
stdenv.mkDerivation rec {
  pname = "libFM";
  version = "30b9c799c41d043f31565cbf827bf41d0dc3e2ab";

  src = "${fetchFromGitHub
    {
      owner = "srendle";
      repo = pname;
      rev = "${version}";
      sha256 = lib.fakeSha256;
      # sha256 = "sha256-QZdGXQtGubLHs3n1cuysbFotCiFh+T41BhvxIUTSDJY=";
    }}";

  doCheck = true;
  # dontUnpack = true;

  nativeBuildInputs = [
    gnumake
    pkg-config
    gcc
  ];

  installPhase = ''
    mkdir -p $out/bin
    make all
    cp ./bin/libFM $out/bin/libFM
    cp ./bin/convert $out/bin/libFM-convert
    cp ./bin/transpose $out/bin/libFM-transpose'';

  meta = { };
}
