{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      dracula-theme.theme-dracula
      vscodevim.vim
      yzhang.markdown-all-in-one
      golang.go
      ms-python.python
      eamodio.gitlens
      christian-kohler.path-intellisense
      ms-vscode-remote.remote-ssh
      ms-vsliveshare.vsliveshare
    ];
  };

  programs.helix = {
    enable = true;
    languages = [
      {
        auto-format = false;
        name = "rust";
      }
      { name = "python"; }
    ];
  };

  programs.neovim = { enable = true; };

  programs.newsboat = { enable = true; };
}
