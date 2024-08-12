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
    ./fonts.nix
  ];
  home.enableNixpkgsReleaseCheck = true;

  home.packages = with pkgs; [
    any-nix-shell
    nixpkgs-fmt
    # inputs.comma.packages.${system}.default
    ncdu # disk space info (a better du)
  ];

  programs.eza = {
    # better 'ls'
    enable = true;
  };


  programs.home-manager.enable = true;
}
