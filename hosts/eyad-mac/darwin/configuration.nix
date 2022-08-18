{ config
, lib
, pkgs
, ...
}:
{
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  homebrew = {
    enable = true;
    autoUpdate = false;
    cleanup = "zap";
    brews = [ "mas" ];
    casks = [ ];
    taps = [ "homebrew/cask-fonts" "mongodb/brew" ];
  };
  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    enableCompletion = true;
    enableFzfCompletion = true;
    enableSyntaxHighlighting = true;
  };
  programs.tmux.enable = true;
  programs.vim.enable = true;
  #  services.mopidy.enable = true;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  # system.keyboard.remapCapsLockToEscape = true;

  # Add ability to used TouchID for sudo authentication
  security.pam.enableSudoTouchIdAuth = true;
  # programs.fish.enable = true;
  networking.computerName = "eyad-mac";
  networking.hostName = "eyad-mac";
  networking.localHostName = "eyad-mac";
  environment.systemPackages = with pkgs; [
    micro
    vscode
    firefox-bin
    kitty
    terminal-notifier
  ];

  # https://github.com/nix-community/home-manager/issues/423
  environment.variables = {
    TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
  };
  programs.nix-index.enable = true;

  # Fonts
  fonts.enableFontDir = true;
  fonts.fonts = with pkgs; [
    recursive
    (nerdfonts.override { fonts = [ "JetBrainsMono" ]; })
  ];
}
