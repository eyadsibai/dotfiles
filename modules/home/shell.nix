{
  lib,
  pkgs,
  isArch,
  ...
}:
let
  pacmanBin = import ./pacman-bin.nix pkgs;
in
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

  # pip only inside a virtualenv (the guard below says what to run instead), and
  # bytecode in one cache folder rather than __pycache__ beside the code
  home.sessionVariables = {
    PIP_REQUIRE_VIRTUALENV = "true";
    PYTHONPYCACHEPREFIX = "$HOME/.cache/pycache";
  };

  # On Arch the shells and tools come from pacman; Home Manager writes their config
  programs.bash = {
    enable = true;
    package = lib.mkIf isArch null;
    # On Arch, ~/.bashrc is this file, so it has to load Omarchy itself (on NixOS,
    # nixarchy does it from /etc); the environment part runs for scripts as well
    bashrcExtra = lib.optionalString isArch ''
      [[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap
    '';
    initExtra = lib.mkMerge [
      (lib.mkBefore (lib.optionalString isArch ''source "$OMARCHY_PATH/default/bash/rc"''))
      ''
        pip() {
          if [[ -n ''${VIRTUAL_ENV:-} ]]; then
            command pip "$@"
          else
            echo 'pip is blocked outside a virtualenv. Use: uv venv .venv && source .venv/bin/activate && uv sync' >&2
            return 1
          fi
        }
        pip3() { pip "$@"; }

        # Tokens and keys stay out of the repo (mode 600, untracked)
        [[ -r ~/.config/secrets/env ]] && source ~/.config/secrets/env
      ''
    ];
  };

  programs.zsh = {
    enable = true;
    package = lib.mkIf isArch null;
    enableCompletion = true;
  };

  programs.nushell = {
    enable = true;
    package = lib.mkIf isArch null;
    loadSessionVariables = false; # keep pre-26.11 behaviour
  };

  # The nushell hooks for carapace and starship are made by running the program at
  # build time, which pacman's copy can't do from inside the build; on Arch, nushell
  # goes without them
  programs.carapace = {
    enable = true;
    package = lib.mkIf isArch (pacmanBin {
      bin = "carapace";
      from = pkgs.carapace;
    });
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = !isArch;
  };

  # Omarchy's prompt plus context that shows only when it applies (see starship.toml),
  # the same on every host; nushell is the only shell Omarchy's own init doesn't cover
  programs.starship = {
    enable = true;
    package = lib.mkIf isArch (pacmanBin {
      bin = "starship";
      from = pkgs.starship;
    });
    enableBashIntegration = true;
    enableZshIntegration = true;
    enableNushellIntegration = !isArch;
    settings = lib.importTOML ./starship.toml;
  };
}
