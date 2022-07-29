{ pkgs, ... }: {

  home.packages = with pkgs; [
    khal
    calcurse # A calendar and scheduling application for the command line

  ];
  programs.himalaya = { enable = true; };

  programs.neomutt = { enable = true; };
}
