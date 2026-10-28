# GUI applications for Linux desktops (macOS hosts get these via Homebrew casks)
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    ghostty
    spotify
    jetbrains.idea
    zed-editor
    vscode

    # chat
    slack
    signal-desktop
    zoom-us
    discord
  ];
}
