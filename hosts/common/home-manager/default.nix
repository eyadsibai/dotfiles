{ inputs
, lib
, pkgs
, config
, outputs
, ...
}: {
  imports = [
    ./version_control.nix
  ];
  home.enableNixpkgsReleaseCheck = true;

  home.packages = with pkgs; [
    rnix-lsp
    any-nix-shell
    nixpkgs-fmt
    comma
    ncdu # disk space info (a better du)
  ];

  fontProfiles = {
    enable = true;
    monospace = {
      family = "FiraCode Nerd Font";
      package = pkgs.nerdfonts.override { fonts = [ "FiraCode" ]; };
    };
    regular = {
      family = "Fira Sans";
      package = pkgs.fira;
    };
  };

  programs.exa = {
    # better 'ls'
    enable = true;
    enableAliases = true;
  };
}
