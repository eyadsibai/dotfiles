{ pkgs, ... }: {
  programs.neovim = {
    enable = false;
    viAlias = true;
    vimAlias = true;
  };
}
