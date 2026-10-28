# Fonts are listed explicitly instead of relying on the desktop's defaults, which
# change between releases. nixarchy adds Omarchy's own (JetBrains Mono Nerd Font etc.).
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    source-code-pro
    nerd-fonts.symbols-only # icon glyphs for starship and eza in any terminal
  ];
}
