{ pkgs, ... }: 



{ 
  home.packages = with pkgs; [
        discord
            signal-desktop
    skypeforlinux
    slack
    slack-term
        zoom-us
    element-desktop
        pkgs.tdesktop
    pkgs.teams
  ];
  
  programs.hexchat = { enable = true; }; 
  
  
  }
