{ pkgs, ... }: {
  home.packages = with pkgs; [
    # khal
    # A calendar and scheduling application for the command line
    gcalcli
    # goobook
  ];



}
