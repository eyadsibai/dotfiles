{ pkgs, lib, ... }:

{
  programs.bash = {
    enable = true;
    initExtra = "neofetch";

  };

  # programs.zsh = {
  #   enable = true;
  #   oh-my-zsh = {
  #     enable = true;
  #     plugins = [ "git" "thefuck" ];
  #     theme = "robbyrussell";
  #   };

  # autocd = true;
  # };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    enableCompletion = true;
    plugins = [

      {
        name = "powerlevel10k";
        src = pkgs.zsh-powerlevel10k;
        file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
      }
      {
        name = "powerlevel10k-config";
        src = lib.cleanSource ./p10k-config;
        file = "p10k.zsh";
      }
    ];
  };

  programs.fish = { enable = true; };
}
