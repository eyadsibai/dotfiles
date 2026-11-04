# Home Manager on its own, on the machines that run Omarchy on Arch. Omarchy and
# pacman own the system, the desktop and the GUI apps (arch/<host>.packages); this
# adds what every machine shares: shells, CLI tools, git, ssh, and the files/ packages.
{
  pkgs,
  username,
  ...
}:
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

  home.shellAliases = {
    hx = "helix"; # Arch names the binary helix
    yayaur = "yay -Syu --config /etc/pacman-aur.conf";
  };

  home.sessionVariables = {
    LC_ALL = "en_US.UTF-8";
    BUN_INSTALL = "/mnt/scratch/bun"; # pacman's /usr/bin/bun stays first; only its data moves
  };

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
