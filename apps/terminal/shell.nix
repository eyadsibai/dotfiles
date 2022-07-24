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

  # enableAutosuggestions = true;
  # enableCompletion = true;
  # enableSyntaxHighlighting = true;
  # autocd = true;
  # };

  programs.zsh = {
    enable = true;
    plugins = [
      {
        name = "zsh-autosuggestions";
        src = pkgs.fetchFromGitHub {
          owner = "zsh-users";
          repo = "zsh-autosuggestions";
          rev = "v0.6.4";
          sha256 = "0h52p2waggzfshvy1wvhj4hf06fmzd44bv6j18k3l9rcx6aixzn6";
        };
      }
      {
        name = "fast-syntax-highlighting";
        src = pkgs.fetchFromGitHub {
          owner = "zdharma";
          repo = "fast-syntax-highlighting";
          rev = "v1.55";
          sha256 = "0h7f27gz586xxw7cc0wyiv3bx0x3qih2wwh05ad85bh2h834ar8d";
        };
      }
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
