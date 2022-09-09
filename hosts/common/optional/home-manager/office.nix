{ config
, pkgs
, ...
}: {
  home.packages = with pkgs; [ pdfgrep pdftk libreoffice-fresh ];
  programs.sioyek = { enable = false; };
  programs.texlive.enable = true;
}
