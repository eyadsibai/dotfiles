# GUI applications for Linux desktops (macOS hosts get these via Homebrew casks)
{ pkgs, ... }:
{
  home.packages = with pkgs; [
    firefox
    ghostty
    spotify
    lmstudio
    jetbrains.idea
    zed-editor
    vscode
  ];
}
