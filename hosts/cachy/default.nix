# Desktop running Omarchy on Arch, used remotely for development. Home Manager only.
# Interactive shells here are fish; bash stays the login shell and hands over to it.
{ lib, ... }:
{
  my.files = [ "host-cachy" ];
  home.stateVersion = "26.05";

  programs.bash.initExtra = lib.mkOrder 400 ''
    if [[ $(ps --no-header --pid=$PPID --format=comm) != fish && -z ''${BASH_EXECUTION_STRING:-} && $SHLVL == 1 ]]; then
      shopt -q login_shell && exec fish --login || exec fish
    fi
  '';

  programs.fish = {
    enable = true;
    interactiveShellInit = ''
      # fd for fzf's file and directory pickers, with previews
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_OPTS '--preview "bat --style=numbers --color=always --line-range=:300 {}"'
      set -gx FZF_ALT_C_OPTS '--preview "eza --tree --level=1 --icons --color=always {}"'

      if test "$TERM" = xterm-kitty; or set -q KITTY_WINDOW_ID
        alias ssh='kitten ssh'
      end

      test -r ~/.config/secrets/env; and source ~/.config/secrets/env
    '';
    functions = {
      pip = ''
        if set -q VIRTUAL_ENV
          command pip $argv
        else
          echo 'pip is blocked outside a virtualenv. Use: uv venv .venv && source .venv/bin/activate && uv sync' >&2
          return 1
        end
      '';
      pip3 = "pip $argv";
      bwunlock = "set -gx BW_SESSION (bw unlock --raw)";
    };
  };
}
