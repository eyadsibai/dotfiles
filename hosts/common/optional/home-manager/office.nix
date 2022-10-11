{ config
, pkgs
, ...
}: {
  home.packages = with pkgs; [ pdfgrep pdftk pdfchain qpdf libreoffice-fresh ];
  programs.sioyek = {
    enable = true;
    bindings = {
      "move_down" = "j";
      "move_left" = "h";
      "move_right" = "l";
      "move_up" = "k";
      "screen_down" = [ "d" "<C-d>" ];
      "screen_up" = [ "u" "<C-u>" ];
    };
    config = {
      "dark_mode_background_color" = "0.0 0.0 0.0";
      "dark_mode_contrast" = "0.8";
    };
  };
  programs.texlive = {
    enable = false;
    # texlive.combined.scheme-full
  };

}
