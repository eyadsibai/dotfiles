{ pkgs, ... }: {

  home.packages = with pkgs; [

    pkgs.dejavu_fonts
    pkgs.fira-code
    pkgs.jetbrains-mono
    pkgs.nerdfonts
    pkgs.source-code-pro
    pkgs.ubuntu_font_family

  ];

  fonts.fontconfig.enable = true;

}
