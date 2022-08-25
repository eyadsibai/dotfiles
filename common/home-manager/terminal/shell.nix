{ pkgs
, lib
, ...
}:
{
  programs.bash = {
    enable = false;
    initExtra = "neofetch";
    historyIgnore = [ "exit" "tree" ];
  };

  programs.zsh = {
    enable = true;
    enableAutosuggestions = true;
    enableSyntaxHighlighting = true;
    enableCompletion = true;
    autocd = true;
    history =
      {
        ignoreDups = true;
        ignorePatterns = [ "exit" "tree" "rm *" ];
      };
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
  programs.fish = { enable = false; };
}