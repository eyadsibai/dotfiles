{ lib, config, pkgs, username, ... }:

let
  cfg = config.shell.starship;
in
{
  options.shell.starship = {
    enable = lib.mkEnableOption "Starship prompt configuration";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users."${username}" = {
      programs.starship = {
        enable = true;
        enableBashIntegration = true; # Consider making these conditional on bash/zsh/nu enable options
        enableZshIntegration = true;
        enableNushellIntegration = true;
        enableTransience = true;
        settings = {
          format = builtins.concatStringsSep "" [
            "$nix_shell"
            "$os"
            "$directory"
            "$container"
            "$git_branch $git_status"
            "$python"
            "$nodejs"
            "$lua"
            "$rust"
            "$java"
            "$c"
            "$golang"
            "$cmd_duration"
            "$status"
            "$line_break"
            "[❯](bold purple)"
            ''''${custom.space}''
          ];
          character = {
            success_symbol = "[›](bold green)";
            error_symbol = "[›](bold red)";
          };
          aws = {
            symbol = "🅰 ";
          };
          gcloud = {
            format = "on [$symbol$active(\($region\))]($style) ";
            symbol = "🅶 ️";
          };
        };
      };
    };
  };
}
