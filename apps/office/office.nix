{ pkgs, ... }: {

  home.pacakges = [ pkgs.pdfgrep pkgs.pdftk ];

  programs.sioyek = { enable = true; };

  programs.texlive.enable = true;

  programs.zathura.enable = true;
}
