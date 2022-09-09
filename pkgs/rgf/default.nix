{ fetchFromGitHub
, lib
, stdenv
, gcc
, gnumake
, pkg-config
,
}:
stdenv.mkDerivation rec {
  pname = "rgf";
  version = "3.12.0";

  src = "${fetchFromGitHub
    {
      owner = "RGF-team";
      repo = pname;
      rev = "${version}";
      sha256 = "sha256-QZdGXQtGubLHs3n1cuysbFotCiFh+T41BhvxIUTSDJY=";
    }}/RGF";

  doCheck = true;
  # dontUnpack = true;

  nativeBuildInputs = [
    gnumake
    pkg-config
    gcc
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir bin
    cd build
    make
    cp ../bin/rgf $out/bin'';

  meta = with lib; {
    homepage = "https://github.com/RGF-team/rgf";
    description = "
      Regularized
      Greedy
      Forest
      (RGF) ";
  };
}
