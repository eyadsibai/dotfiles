{ stdenv, lib, qmake, pkg-config, qtbase, qtdeclarative, qtlocation, qtwebchannel, qtwebengine, wrapQtAppsHook, fetchFromGitHub, gnumake }:



stdenv.mkDerivation rec {
  pname = "whatsie";
  version = "4.9.0";

  src = fetchFromGitHub
    {
      owner = "keshavbhatt";
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-O8mBRBb24Owt+JPuAA9khvvu512anE3NKKUwUAaRdkI=";
    } + "/src";

  buildInputs = [ qtbase qtdeclarative qtlocation qtwebchannel qtwebengine ];
  nativeBuildInputs = [ qmake wrapQtAppsHook ];

  #phases = [ "installPhase"];

  # installPhase = ''
  # '';

  # dontUseQmakeConfigure = true;
  # postBuild = ''
  # make
  # '';
  #
  # installPhase = ''
  # make install
  # '';

  # dontWrapQtApps = true;
  meta.broken = lib.versionOlder qtbase.version "5.9.0";

}
