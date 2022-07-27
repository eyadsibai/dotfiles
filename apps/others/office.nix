{ config, pkgs, inputs, ... }: {

  home.packages = [ pkgs.pdfgrep pkgs.pdftk ];

  programs.sioyek = { enable = true; };

  programs.texlive.enable = true;

  programs.zathura = { enable = true; };
}
