{ config, pkgs, ... }:
{
  programs.nix-index = {
    enable = true;
    enableBashIntegration = config.programs.bash.enable;
    enableZshIntegration = config.programs.zsh.enable;
    enableFishIntegration = config.programs.fish.enable;
  };

  #  builtins.trace ${config.programs.fish.enable}
  home.file.".cache/nix-index".source = pkgs.nix-index-database;
}
