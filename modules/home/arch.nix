# Home Manager on its own, on the machines that run Omarchy on Arch. Omarchy and
# pacman own the system, the desktop and the GUI apps (arch/<host>.packages); this
# adds what every machine shares: shells, CLI tools, git, ssh, and the files/ packages.
{
  config,
  lib,
  pkgs,
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

  # Omarchy's LazyVim owns ~/.config/nvim/init.lua; load Home Manager's provider
  # settings through the wrapper instead of overwriting it.
  programs.neovim.sideloadInitLua = true;

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

  programs.bash.initExtra = ''
    bwunlock() { export BW_SESSION=$(bw unlock --raw); }
    gh-relogin() {
      [ -z "$BW_SESSION" ] && bwunlock
      bw get password "GitHub CLI" | gh auth login --hostname github.com --with-token
    }
  '';
}
