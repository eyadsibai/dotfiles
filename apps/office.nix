{
  config,
  pkgs,
  inputs,
  ...
}: {
  home.packages = with pkgs; [pdfgrep pdftk libreoffice-fresh];

  programs.sioyek = {enable = true;};

  programs.texlive.enable = true;

  # TODO https://github.com/LukeSmithxyz/voidrice/blob/master/.config/zathura/zathurarc
  programs.zathura = {enable = true;};
}
