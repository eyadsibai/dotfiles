{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  imports = [ ./version_control.nix ];
  home.enableNixpkgsReleaseCheck = true;
  home.packages = [
    pkgs.rnix-lsp
  ];
}
