# Fonts are listed explicitly instead of relying on the desktop's defaults, which
# change between releases (GNOME 50 dropped Cantarell and Source Code Pro).
{ pkgs, ... }:
{
  fonts.packages = with pkgs; [
    source-code-pro # GNOME Console is configured to use it
    nerd-fonts.symbols-only # icon glyphs for starship and eza in any terminal
  ];
}
