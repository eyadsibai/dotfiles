{ config, pkgs, ... }:
{
  fonts = {
    enableDefaultFonts = true;
    fontDir.enable = true;
    enableGhostscriptFonts = true;
    fonts = with pkgs; [
      corefonts
      dejavu_fonts
      source-code-pro
      ubuntu_font_family
      fira-code
      jetbrains-mono
      font-awesome # awesome fonts
      material-design-icons # fonts with glyphs
      ubuntu_font_family
      line-awesome
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
  };

}