{ fetchFromGitHub
, lib
, stdenv
, gcc
, gnumake
, cmake
, pkg-config
,
}:
stdenv.mkDerivation rec {
  pname = "fast-rgf";
  version = "3.12.0";

  src = "${fetchFromGitHub
    {
      owner = "RGF-team";
      repo = "rgf";
      rev = "${version}";
      sha256 = "sha256-QZdGXQtGubLHs3n1cuysbFotCiFh+T41BhvxIUTSDJY=";
    }}/FastRGF";

  doCheck = true;
  # dontUnpack = true;

  nativeBuildInputs = [
    gnumake
    gcc
    cmake
    pkg-config
  ];

  installPhase = ''
    mkdir -p $out/bin
    mkdir -p ../bin
    cmake ..
    echo $(pwd)
    make
    make install
    cp -r ../bin/* $out/bin
    # cp ../bin/forest_predict $out/bin
    # cp ../bin/forest_train $out/bin
  '';

  meta = with lib; {
    homepage = "https://github.com/RGF-team/rgf/FastRGF";
    description = "
      Fast Regularized
      Greedy
      Forest
      (RGF) ";
  };
}
