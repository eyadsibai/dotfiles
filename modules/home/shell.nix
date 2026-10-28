{ lib, pkgs, ... }:
{
  # Helpers carried over from the old fish setup, as scripts so every shell has them
  home.packages = [
    (pkgs.writeShellApplication {
      name = "x"; # extract any archive
      runtimeInputs = with pkgs; [
        gnutar
        bzip2
        gzip
        unzip
        p7zip
        unrar
      ];
      text = ''
        [ -f "$1" ] || { echo "'$1' is not a valid file" >&2; exit 1; }
        case "$1" in
          *.tar.bz2|*.tbz2) tar xjf "$1" ;;
          *.tar.gz|*.tgz) tar xzf "$1" ;;
          *.tar.xz|*.tar.zst|*.tar) tar xf "$1" ;;
          *.bz2) bunzip2 "$1" ;;
          *.gz) gunzip "$1" ;;
          *.rar) unrar x "$1" ;;
          *.zip) unzip "$1" ;;
          *.7z) 7z x "$1" ;;
          *) echo "'$1' cannot be extracted via x" >&2; exit 1 ;;
        esac
      '';
    })
    (pkgs.writeShellScriptBin "wh" ''readlink -f "$(command -v "$1")"'') # where a command really lives
    (pkgs.writeShellScriptBin "gitignore" ''${pkgs.curl}/bin/curl -sL "https://www.toptal.com/developers/gitignore/api/$1"'')
    (pkgs.writeShellScriptBin "getip" "${pkgs.curl}/bin/curl -s ifconfig.me; echo")
  ];

  home.shellAliases = {
    df = "df -h";
    free = "free -m";
    cp = "cp -i";
  };

  programs.bash.enable = true;

  programs.zsh = {
    enable = true;
    enableCompletion = true;
  };

  programs.nushell = {
    enable = true;
    loadSessionVariables = false; # keep pre-26.11 behaviour
  };

  programs.carapace = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
  };

  # Omarchy's prompt (config/starship.toml from the Omarchy tree, copied here so the
  # Macs match); nushell is the only shell Omarchy's own init doesn't cover
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = true;
    settings = lib.importTOML ./starship.toml;
  };
}
