# Omarchy's own Qt apps (github.com/omacom), preinstalled on Arch from Omarchy's
# package repo but not packaged by nixarchy. Built the way their PKGBUILDs do it:
# qmake + make, then the binary, desktop entry and icon.
{
  lib,
  stdenv,
  fetchFromGitHub,
  makeBinaryWrapper,
  pkg-config,
  qt6,
  kdePackages,
  ffmpeg,
  libpulseaudio,
  libwebp,
  qpdf,
  sourceHighlight,
  zlib,
}:
let
  mkApp =
    {
      pname,
      version,
      hash,
      description,
      qtModules ? [ ],
      buildInputs ? [ ],
      nativeBuildInputs ? [ ],
      # Programs the app starts by name
      runtimePath ? [ ],
    }:
    stdenv.mkDerivation {
      inherit pname version;

      src = fetchFromGitHub {
        owner = "omacom";
        repo = pname;
        tag = "v${version}";
        inherit hash;
      };

      nativeBuildInputs = [
        qt6.qmake
        qt6.wrapQtAppsHook
      ]
      ++ lib.optional (runtimePath != [ ]) makeBinaryWrapper
      ++ nativeBuildInputs;

      buildInputs = [
        qt6.qtbase
        qt6.qtdeclarative
        qt6.qtwayland
      ]
      ++ qtModules
      ++ buildInputs;

      qtWrapperArgs = lib.optionals (runtimePath != [ ]) [
        "--prefix PATH : ${lib.makeBinPath runtimePath}"
      ];

      installPhase = ''
        runHook preInstall
        install -Dm755 ${pname} $out/bin/${pname}
        install -Dm644 $src/pkgbuild/${pname}.desktop $out/share/applications/${pname}.desktop
        install -Dm644 $src/pkgbuild/${pname}.svg $out/share/icons/hicolor/scalable/apps/${pname}.svg
        runHook postInstall
      '';

      meta = {
        inherit description;
        homepage = "https://github.com/omacom/${pname}";
        license = lib.licenses.mit;
        platforms = lib.platforms.linux;
        mainProgram = pname;
      };
    };
in
{
  hype = mkApp {
    pname = "hype";
    version = "0.6.0";
    hash = "sha256-lDrDfo0LqGbWD8X7rejOYf9nKqyNNZh6wMlL9wRRJoU=";
    description = "Simple Markdown presentations with a visual slide editor";
    qtModules = with qt6; [
      qtmultimedia
      qtsvg
      qtimageformats
    ];
    buildInputs = [
      zlib
      libwebp
    ];
    # Video export and probing, and code-block highlighting
    runtimePath = [
      ffmpeg
      sourceHighlight
    ];
  };

  monologue = mkApp {
    pname = "monologue";
    version = "0.3.1";
    hash = "sha256-sQm/n0kHl13JQ3iOcOM5rZcP9xqrPpw6EKTVBLWha/I=";
    description = "A simple, theme-synced webcam recorder for Omarchy";
    qtModules = [ qt6.qtmultimedia ];
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [ libpulseaudio ];
  };

  signed = mkApp {
    pname = "signed";
    version = "0.3.1";
    hash = "sha256-fH5jXdO0uNsRblramzU0lcP3Dvv7pMZjf41FdE3lKjY=";
    description = "Sign PDFs and fill them in with text and dates";
    nativeBuildInputs = [ pkg-config ];
    buildInputs = [
      kdePackages.poppler
      qpdf
    ];
  };
}
