{ pkgs, ... }: {
  programs.sioyek = { enable = true; };

  programs.texlive.enable = true;

  programs.zathura.enable = true;
}
