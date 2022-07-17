{ lib, config, pkgs, ... }: 


{
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        title = "Terminal";
        opacity = 0.7;
        # dimensions = {
        #   lines = 75;
        #   columns = 100;
        # };
      };

      font = {
        normal.family = "JetbrainsMono Nerd Font";
        size = 8.0;
      };

      shell = {
        program = "${pkgs.zsh}/bin/zsh";
        args = [ "-c" "echo; neofetch; echo; zsh" ];
      };

    };
  };
}
