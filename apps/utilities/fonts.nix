{ pkgs, ... }: {

  home.packages = with pkgs; [

    dejavu_fonts
    fira-code
    jetbrains-mono
    nerdfonts
    source-code-pro
    font-awesome # awesome fonts
    material-design-icons # fonts with glyphs
    ubuntu_font_family

  ];

  fonts.fontconfig.enable = true;

}
