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
}
