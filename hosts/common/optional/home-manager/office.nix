{ config
, pkgs
, ...
}: {
  home.packages = with pkgs; [ pdfgrep pdftk pdfchain qpdf libreoffice-fresh ];
  programs.sioyek = { enable = false; };
  programs.texlive.enable = true;
}
