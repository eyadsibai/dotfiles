# Desktop running Omarchy on Arch, used remotely for development. Home Manager only.
# Interactive shells here are fish; bash stays the login shell and hands over to it.
{ lib, pkgs, ... }:
{
  my.files = [ "host-cachy" ];

  # pacman's fish. The module formats the config files it writes with fish_indent at
  # build time, where /usr/bin isn't reachable, so Nix's fish_indent stays for that;
  # pacman's fish ships its own completions, so the man-page ones aren't generated.
  programs.fish.package = import ../../modules/home/pacman-bin.nix pkgs {
    bin = "fish";
    from = pkgs.fish;
    extra = "ln -s ${pkgs.fish}/bin/fish_indent $out/bin/fish_indent";
  };
  programs.fish.generateCompletions = false;
  home.stateVersion = "26.05";

  programs.bash.initExtra = lib.mkOrder 400 ''
    if [[ $(ps --no-header --pid=$PPID --format=comm) != fish && -z ''${BASH_EXECUTION_STRING:-} && $SHLVL == 1 ]]; then
      shopt -q login_shell && exec fish --login || exec fish
    fi
  '';

  # The DGX, the workstation and Azure DevOps, as reached from here. Order matters for
  # the DGX: the direct-cable Match has to come after `dgx` names it and before the
  # tailnet fallback sets HostName.
  programs.ssh = {
    includes = [ "~/.config/NVIDIA/Sync/config/ssh_config" ];
    settings = {
      "Host Eyads-laptop" = {
        HostName = "Eyads-laptop";
        User = "eyad";
      };
      "Host dgx".HostName = "aitopatom-tnerd";
      "Match host aitopatom-tnerd exec \"ping -c1 -W1 -I enp2s0 10.42.0.2 >/dev/null 2>&1\"" =
        lib.hm.dag.entryBetween [ "Host aitopatom-tnerd" ] [ "Host dgx" ]
          {
            HostName = "10.42.0.2";
            BindInterface = "enp2s0";
            AddressFamily = "inet";
          };
      "Host aitopatom-tnerd".HostName = "aitopatom-tnerd.gate-delta.ts.net";
      "Host ssh.dev.azure.com vs-ssh.visualstudio.com" = {
        User = "git";
        IdentityFile = "~/.ssh/id_rsa_azure";
        IdentitiesOnly = "yes";
      };
      "Host workstation".HostName = "workstation.local";
      "Host workstation-ts" = {
        HostName = "100.115.116.117";
        HostKeyAlias = "workstation.local";
      };
      # drover's own key, so unattended jobs never wait on a 1Password prompt
      "Host workstation-drover" = {
        HostName = "100.115.116.117";
        HostKeyAlias = "workstation.local";
        User = "eyad";
        IdentityFile = "~/.ssh/drover_workstation";
        IdentitiesOnly = "yes";
        IdentityAgent = "none";
      };
    };
  };

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
