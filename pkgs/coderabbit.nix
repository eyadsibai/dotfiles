# CodeRabbit's AI code review CLI (coderabbit.ai/cli), from the release archive its
# install.sh downloads. It is not in nixpkgs. Bump `version` to the installer's
# BUNDLED_LINUX_VERSION and refresh the hashes with `nix store prefetch-file`.
{
  lib,
  stdenv,
  fetchurl,
  unzip,
  autoPatchelfHook,
}:
let
  platforms = {
    x86_64-linux = {
      target = "linux-x64";
      hash = "sha256-spvvVf1aQaKHKThRas3kb0wMz4/YHA2GgpxDWnWl/Zo=";
    };
    aarch64-linux = {
      target = "linux-arm64";
      hash = "sha256-RWfqQtDFKm9RNBgNIuXw3k51cys+JfsaXFpDPMqhDZw=";
    };
    aarch64-darwin = {
      target = "darwin-arm64";
      hash = "sha256-vzypbAjlpXhug3A+KF4w20PdJuDm3Fm4LZB03cqluFQ=";
    };
  };
  platform = platforms.${stdenv.hostPlatform.system};
in
stdenv.mkDerivation (finalAttrs: {
  pname = "coderabbit";
  version = "0.9.2";

  src = fetchurl {
    url = "https://cli.coderabbit.ai/releases/${finalAttrs.version}/coderabbit-${platform.target}.zip";
    inherit (platform) hash;
  };

  nativeBuildInputs = [ unzip ] ++ lib.optional stdenv.hostPlatform.isLinux autoPatchelfHook;

  sourceRoot = ".";

  # a single-file executable with its payload appended: stripping it breaks it
  dontStrip = true;

  installPhase = ''
    runHook preInstall
    install -Dm755 coderabbit $out/bin/coderabbit
    ln -s coderabbit $out/bin/cr
    runHook postInstall
  '';

  meta = {
    description = "AI code reviews for local changes from the terminal";
    homepage = "https://www.coderabbit.ai/cli";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = builtins.attrNames platforms;
    mainProgram = "coderabbit";
  };
})
