# GUI apps and anything nixpkgs lacks (or ships poorly) on macOS
{
  homebrew = {
    enable = true;
    onActivation = {
      autoUpdate = true;
      cleanup = "zap"; # remove anything not listed here
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
      windows-app = 1295203466;
    };

    taps = [
      "nikitabobko/tap"
      "dimentium/autoraise"
      "localsend/localsend"
      "colindean/fonts-nonfree"
    ];

    brews = [
      "kakoune"
      "helix"
      "rust"
      "neovim"
      "rustup"
      "python"
      "gemini-cli"
      "opencode"
      "gh"
    ];

    casks = [
      "codex"
      "kitty"
      "visual-studio-code"
      "akiflow"
      "raycast"
      "readdle-spark"
      "font-sf-pro"
      "font-sf-mono"
      "sf-symbols"
      "capacities"
      "netdownloadhelpercoapp"
      "steam"
      "send-to-kindle"
      "font-microsoft-office"
      "webex-meetings"
      "microsoft-remote-desktop"
      "rocket"
      "desktoppr"
      "zen"
      "floorp"
      "trae"
      "meetingbar"
      "homerow"
      "qutebrowser"
      "docker-desktop"
      "hey-desktop"
      "chatgpt"
      "basecamp"
      "plex"
      "raindropio"
      "claude"
      "notion"
      "grammarly-desktop"
      "linear-linear"
      "twist"
      "intellij-idea-ce"
      "anytype"
      "stats"
      "dupeguru"
      "imageoptim"
      "boop"
      "transnomino"
      "hammerspoon"
      "only-switch"
      "shottr"
      "the-unarchiver"
      "hiddenbar"
      "reader"
      "wechat"
      "warp"
      "canva"
      "actual"
      "huggingchat"
      "dropbox"
      "keyboardcleantool"
      "tailscale-app"
      "thunderbird"
      "google-chrome"
      "telegram-desktop"
    ];
  };
}
