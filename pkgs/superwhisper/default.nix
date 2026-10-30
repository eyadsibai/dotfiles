# Superwhisper (local and cloud voice dictation), from the Omarchy release bundle
# that Omarchy's superwhisper-bin repackages. Proprietary and prebuilt: the
# binaries are patched to find their libraries, and the launcher gets the
# programs and GObject typelibs the Arch package lists as dependencies.
# The user service and Omarchy wiring are in modules/home/omarchy-apps.nix.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  python3,
  zstd,
  cairo,
  fontconfig,
  gdk-pixbuf,
  glib,
  gobject-introspection,
  graphene,
  gtk4,
  gtk4-layer-shell,
  at-spi2-core,
  harfbuzz,
  pango,
  libGL,
  librsvg,
  libxcb,
  libxkbcommon,
  vulkan-loader,
  wayland,
  ffmpeg,
  foot,
  libnotify,
  pipewire,
  pulseaudio,
  wl-clipboard,
  wtype,
  xdg-utils,
}:
let
  python = python3.withPackages (ps: [
    ps.pygobject3
    ps.pycairo
  ]);

  # Typelibs for its Python helpers (the paste confirmation, field capture and
  # accessibility inventory use GTK 4, the layer shell and AT-SPI)
  typelibs = [
    gtk4
    gtk4-layer-shell
    at-spi2-core
    gdk-pixbuf
    glib
    gobject-introspection # cairo
    graphene
    harfbuzz
    pango
  ];

  # Programs it runs by name: clipboard, paste keystrokes, notifications, audio
  # capture and playback, transcoding, and Python for its helpers
  runtimePath = [
    python
    ffmpeg
    libnotify
    pipewire
    pulseaudio
    wl-clipboard
    wtype
    xdg-utils
    glib.bin # gsettings
  ];
in
stdenv.mkDerivation (finalAttrs: {
  pname = "superwhisper";
  version = "1.1.2";

  src = fetchurl {
    url = "https://tux.superwhisper.com/x86_64/v${finalAttrs.version}/superwhisper-omarchy-x86_64-${finalAttrs.version}.tar.zst";
    hash = "sha256-qVoaYpm1kVoHTkfPkdOKQ17QoatLKH7zkTcPFOuIxoQ=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
    python3
    zstd
  ];

  buildInputs = [
    stdenv.cc.cc.lib # libstdc++, libgomp
    cairo
    fontconfig
    gdk-pixbuf
    glib
    graphene
    gtk4
    libxcb
    libxkbcommon
    vulkan-loader
  ];

  # Loaded at runtime: the settings window's Wayland and GPU libraries, and the
  # layer shell the recording indicator preloads by name
  runtimeDependencies = [
    wayland
    libGL
    vulkan-loader
    gtk4-layer-shell
  ];

  # Qt 6.12 adds a Color type that shadows Omarchy's palette singleton in the
  # bar panel; qualify it, as Omarchy's PKGBUILD does
  postPatch = ''
    python3 ${./qualify-color.py} app/assets/omarchy-plugin/superwhisper-panel
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/opt
    cp -a app $out/opt/superwhisper
    # Omarchy owns its Dictation menu; the fcitx5 addon is left out (NixOS loads
    # addons only through i18n.inputMethod), so dictation pastes instead
    rm -rf $out/opt/superwhisper/scripts/omarchy-menu-rows.py $out/opt/superwhisper/lib/fcitx5

    mkdir -p $out/bin
    substitute ${./superwhisper} $out/bin/superwhisper \
      --subst-var-by app $out/opt/superwhisper
    chmod +x $out/bin/superwhisper

    install -Dm644 app/assets/linux-status/SuperwhisperTUI.ttf $out/share/fonts/truetype/SuperwhisperTUI.ttf
    for size in 16 32 64 128 256 512 1024; do
      install -Dm644 app/assets/app-icon/$size.png $out/share/icons/hicolor/''${size}x''${size}/apps/superwhisper.png
    done
    mkdir -p $out/share/applications
    substitute ${./superwhisper.desktop} $out/share/applications/superwhisper.desktop \
      --subst-var-by foot ${lib.getExe foot} --subst-var-by out $out
    substitute ${./superwhisper-url.desktop} $out/share/applications/superwhisper-url.desktop \
      --subst-var-by out $out

    runHook postInstall
  '';

  postFixup = ''
    patchShebangs $out/opt/superwhisper/run.sh $out/opt/superwhisper/scripts
    wrapProgram $out/bin/superwhisper \
      --prefix PATH : ${lib.makeBinPath runtimePath} \
      --prefix GI_TYPELIB_PATH : ${lib.makeSearchPath "lib/girepository-1.0" (map lib.getLib typelibs)} \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ gtk4-layer-shell ]} \
      --set-default GDK_PIXBUF_MODULE_FILE ${librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache
  '';

  meta = {
    description = "Local and cloud voice dictation";
    homepage = "https://superwhisper.com";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "superwhisper";
  };
})
