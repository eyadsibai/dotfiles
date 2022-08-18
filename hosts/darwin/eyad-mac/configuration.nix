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
  programs.zsh.enable = true;
  # default shell on catalina
  programs.zsh.enableBashCompletion = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.enableFzfCompletion = true;
  programs.zsh.enableSyntaxHighlighting = true;
  programs.nix-index.enable = true;
  programs.tmux.enable = true;
  programs.vim.enable = true;
  #  services.mopidy.enable = true;
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;
  # programs.fish.enable = true;
  networking.computerName = "eyad-mac";
  networking.hostName = "eyad-mac";
  networking.localHostName = "eyad-mac";
  environment.systemPackages = [
    pkgs.micro
    pkgs.vscode
    pkgs.firefox-devedition-bin
  ];
}
