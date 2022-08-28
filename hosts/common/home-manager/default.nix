{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  home.enableNixpkgsReleaseCheck = true;
  home.packages = [
    pkgs.rnix-lsp
  ];
}
