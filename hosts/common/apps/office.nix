{ config
, pkgs
, ...
}:
{
  home.packages = with pkgs; [ pdfgrep pdftk libreoffice-fresh ];
  programs.sioyek = { enable = true; };
  programs.texlive.enable = true;
}
