{ lib, config, pkgs, ... }:

let
  cfg = config.darwin.homebrew;
in
{
  options.darwin.homebrew = {
    enable = lib.mkEnableOption "Enable Homebrew integration";
    # Add options for taps, brews, casks, masApps if more control is needed
  };

  config = lib.mkIf (cfg.enable && pkgs.stdenv.isDarwin) {
    # From Darwin darwin/apps.nix
    homebrew = {
      enable = true;
      onActivation = {
        autoUpdate = true;
        cleanup = "zap";
        upgrade = true;
      };
      masApps = {
        keynote = 409183694;
        numbers = 409203825;
        pages = 409201541;
        "amazon prime videos" = 545519333;
        bitwarden = 1352778147;
        Vimari = 1480933944;
        grab2text = 6475956137;
        trello = 1278508951;
        "windows-app" = 1295203466; # Microsoft Remote Desktop
      };
      taps = [
        "homebrew/services"
        "homebrew/bundle"
        "FelixKratz/formulae"
        "nikitabobko/tap"
        "dimentium/autoraise"
        "localsend/localsend"
      ];
      brews = [
        "r"
        "curl" # Prefer brew curl on macOS
        "bitwarden-cli"
        "atuin"
        "dust"
        "tldr"
        "m-cli"
        "sketchybar"
        "borders"
        "spotify_player"
        "docker"
        "lazysql"
        "ffmpeg"
        # "yt-dlp" # Managed by HM apps module (or disabled in host)
        "ttyd"
        # "ripgrep" # Managed by HM shell module
      ];
      casks = [
        # "firefox" # Managed by HM apps module (or disabled in host)
        "google-chrome"
        "visual-studio-code"
        "only-switch"
        "discord" # Keep in Cask for now, HM module is basic
        "webex-meetings"
        # "spotify" # Managed by HM apps module (or disabled in host)
        "iina"
        "raycast"
        "stats"
        "insomnia"
        "chatgpt"
        "shottr"
        "the-unarchiver"
        "keka"
        "appcleaner"
        "akiflow"
        "soundsource"
        "karabiner-elements"
        "hammerspoon"
        "messenger"
        "yandex-disk"
        "readdle-spark"
        "slack"
        "zoom"
        "telegram-desktop" # Also potentially via HM?
        "dropbox"
        "basecamp"
        "hey"
        "raindropio"
        "logseq"
        "send-to-kindle"
        "qutebrowser"
        "grammarly-desktop"
        "notion"
        "wezterm"
        "whatsapp"
        "linear-linear"
        "ticktick"
        "tailscale" # Keep in Cask for Darwin, disable HM service module for macbook host
        "microsoft-teams"
        "microsoft-remote-desktop" # Keep Cask, masApps one is different ID
        "orion"
        "flameshot"
        "font-fira-mono-nerd-font"
        "font-ubuntu-mono-nerd-font"
        "font-caskaydia-cove-nerd-font"
        "font-fira-code-nerd-font"
        "font-hack-nerd-font"
        "font-iosevka-nerd-font"
        "font-jetbrains-mono-nerd-font"
        "font-meslo-lg-nerd-font"
        "font-ubuntu-nerd-font"
        "font-sf-pro"
        "sf-symbols"
        "twist"
        "font-sf-mono"
        # "intellij-idea" # Managed by HM dev module (or disabled in host)
        "anytype"
        "hiddenbar"
        "rocket"
        "imageoptim"
        "transnomino"
        "localsend"
        "capacities"
        "zed"
        "boop"
        "reader"
        "netdownloadhelpercoapp"
        "dupeguru"
        "microsoft-office"
        "siyuan"
        "rstudio"
        "steam"
        "emby"
        "claude"
        "losslesscut"
        "canva"
        "handbrake"
        # "ghostty" # Managed by HM apps module (or disabled in host)
        "huggingchat"
        "actual"
        "trae"
        "plex"
        "lapce"
        "jdownloader"
      ];
    };
  };
}
