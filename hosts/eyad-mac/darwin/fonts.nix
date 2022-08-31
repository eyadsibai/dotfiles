{ pkgs, ... }:
{

  fonts = {
    fontDir.enable = true;
    fonts = with pkgs; [
      # recursive
      # dejavu_fonts
      # source-code-pro
      # jetbrains-mono
      # font-awesome
      # awesome fonts
      # material-design-icons
      # fonts with glyphs
      # ubuntu_font_family
      # line-awesome
      cascadia-code
      (nerdfonts.override { fonts = [ "FiraCode" "JetBrainsMono" ]; })
    ];
  };
}
