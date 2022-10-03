{ pkgs, ... }: {
  home.packages = with pkgs; [
    # khal
    calcurse
    # A calendar and scheduling application for the command line
    gcalcli
    # goobook
  ];
}
