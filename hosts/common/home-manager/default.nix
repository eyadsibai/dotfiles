{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  imports = [
    ./version_control.nix
    ./shellcolor.nix
    ./rice.nix
    ./fonts.nix
  ];
  home.enableNixpkgsReleaseCheck = true;

  home.packages = with pkgs; [
    rnix-lsp
    any-nix-shell
    nixpkgs-fmt
    comma
    ncdu # disk space info (a better du)
  ];

  programs.exa = {
    # better 'ls'
    enable = true;
    enableAliases = true;
  };
  programs.home-manager.enable = true;

}
