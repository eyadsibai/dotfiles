{ pkgs, ... }:

{
  programs.bash = {
    enable = true;
    initExtra = "neofetch";

  };

  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      enable = true;
      plugins = [ "git" "thefuck" ];
      theme = "robbyrussell";
    };

    enableAutosuggestions = true;
    enableCompletion = true;
    enableSyntaxHighlighting = true;
    autocd = true;
  };

  programs.fish = { enable = true; };
}
