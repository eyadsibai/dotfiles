# Home Manager on its own, on the machines that run Omarchy on Arch. Omarchy and
# pacman own the system and every program, CLI tools included (arch/<host>.packages);
# this adds only the config every machine shares: shells, CLI tools, git, ssh, and the
# files/ packages. The shared modules check `isArch` to leave the programs out (or
# point Home Manager at pacman's copy, see pacman-bin.nix). Nix still installs its own
# tooling (nh, nil, nixd, devenv) and Claude Code.
{
  config,
  lib,
  pkgs,
  repoDir,
  username,
  ...
}:
let
  themedStarship = "${config.xdg.stateHome}/omarchy-theme-apps/starship.toml";
in
{
  imports = [
    ./default.nix
    ./files.nix
  ];

  home.username = username;
  home.homeDirectory = "/home/${username}";
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true; # desktop entries and XDG paths for Nix's apps

  # Shared Omarchy tweaks; each host adds its own host-<name> package last
  my.files = [
    "alacritty"
    "foot"
    "ghostty"
    "kitty"
    "hypr"
    "lazygit"
    "media"
    "omarchy"
    "scripts"
    "systemd"
    "tv"
  ];

  home.packages = [ pkgs.nh ];
  programs.man.package = null; # pacman's man-db

  # Omarchy's theme-set links the current theme to ~/.config/btop/themes/current.theme
  programs.btop.settings.color_theme = "current";

  home.shellAliases = {
    hx = "helix"; # Arch names the binary helix
    yayaur = "yay -Syu --config /etc/pacman-aur.conf";
  };

  home.sessionVariables = {
    LC_ALL = "en_US.UTF-8";
    BUN_INSTALL = "/mnt/scratch/bun"; # pacman's /usr/bin/bun stays first; only its data moves
    # The prompt in the current theme's colours: the theme-set hook
    # 60-omarchy-theme-apps.sh (from omarchy-eyad-theme) writes this copy of
    # ~/.config/starship.toml with the theme's palette added. Home Manager's own
    # value would otherwise win in every shell, SSH sessions included.
    STARSHIP_CONFIG = lib.mkForce "${themedStarship}";
  };

  # That copy is made at theme changes, so rebuild it whenever starship.toml may have
  # changed. Without the hook, link the plain config so STARSHIP_CONFIG never dangles.
  home.activation.themedStarship = lib.hm.dag.entryAfter [ "linkGeneration" ] ''
    hook="$HOME/.config/omarchy/hooks/theme-set.d/60-omarchy-theme-apps.sh"
    if [ -x "$hook" ]; then
      run "$hook"
    else
      run mkdir -p "$(dirname "${themedStarship}")"
      run ln -sfn "$HOME/.config/starship.toml" "${themedStarship}"
    fi
  '';

  # Tools installed by their own installers, outside pacman and Nix
  home.sessionPath = [
    "$HOME/.local/share/supabase" # update-supabase
    "$HOME/.lmstudio/bin"
    "$HOME/.local/share/JetBrains/Toolbox/scripts"
    "$HOME/.kimi-code/bin"
    "$HOME/.maestro/bin"
    "$HOME/.grok/bin"
    "/mnt/scratch/bun/bin"
  ];

  # The Omarchy shell saves shell.json by writing a new file and moving it over the
  # old one, which turns the link into a plain file every time the bar is changed in
  # Settings. This puts the file back in the repo and relinks it each time, so the
  # change lands in git diff instead of waiting for `just omarchy-adopt`. It watches
  # the directory: a watch on the file itself dies with the first file replaced.
  # Other writes there trigger it too, and relink does nothing when all is linked.
  systemd.user.paths.omarchy-shell-json-sync = {
    Unit.Description = "Keep ~/.config/omarchy/shell.json linked to the dotfiles repo";
    Path.PathChanged = "%h/.config/omarchy";
    Install.WantedBy = [ "default.target" ];
  };
  systemd.user.services.omarchy-shell-json-sync = {
    Unit.Description = "Copy a detached shell.json into the dotfiles repo and relink it";
    Service = {
      Type = "oneshot";
      ExecStart = "${repoDir}/scripts/omarchy-links relink";
    };
  };

  programs.bash.initExtra = ''
    bwunlock() { export BW_SESSION=$(bw unlock --raw); }
    gh-relogin() {
      [ -z "$BW_SESSION" ] && bwunlock
      bw get password "GitHub CLI" | gh auth login --hostname github.com --with-token
    }
  '';
}
