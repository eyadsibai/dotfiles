{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  imports = [ ./version_control.nix ];
  home.enableNixpkgsReleaseCheck = true;

  home.packages = with pkgs; [
    rnix-lsp
    any-nix-shell
    nixpkgs-fmt
    comma

  ];
}
