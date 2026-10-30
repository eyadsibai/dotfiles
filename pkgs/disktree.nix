# Disk space treemap for Omarchy (github.com/tobi/disktree), from its release
# binary as Omarchy's disktree-bin does. It is a GPUI app: Wayland, EGL and Vulkan
# are loaded at runtime, so they go on its RPATH rather than in DT_NEEDED.
{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeBinaryWrapper,
  libgcc,
  libxkbcommon,
  libxcb,
  wayland,
  libGL,
  vulkan-loader,
  git,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "disktree";
  version = "0.11.0";

  src = fetchurl {
    url = "https://github.com/tobi/disktree/releases/download/v${finalAttrs.version}/disktree-${finalAttrs.version}-x86_64-linux.tar.gz";
    hash = "sha256-fnWvoig8i0+SkNUurb/ADZ8UwTrtLSJMzfD3gm/MBbI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeBinaryWrapper
  ];

  buildInputs = [
    libgcc
    libxkbcommon
    libxcb
  ];

  runtimeDependencies = [
    wayland
    libGL
    vulkan-loader
  ];

  installPhase = ''
    runHook preInstall
    install -Dm755 disktree $out/bin/disktree
    install -Dm644 disktree.svg $out/share/icons/hicolor/scalable/apps/disktree.svg
    sed -e "s|@BINDIR@|$out/bin|" -e "s|@VERSION@|${finalAttrs.version}|" disktree.desktop.in \
      > disktree.desktop
    install -Dm644 disktree.desktop $out/share/applications/disktree.desktop
    runHook postInstall
  '';

  # git shows a selected checkout's changes, stashes and unpushed commits
  postFixup = ''
    wrapProgram $out/bin/disktree --suffix PATH : ${lib.makeBinPath [ git ]}
  '';

  meta = {
    description = "Disk space treemap: see what fills a disk, mark what should go, and remove it";
    homepage = "https://github.com/tobi/disktree";
    license = lib.licenses.mit;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "disktree";
  };
})
