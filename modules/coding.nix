{ pkgs, ... }:
{
  services.envfs.enable = true;

  environment.systemPackages = with pkgs; [
    nixd
    nil
    gnumake
    jetbrains.jdk
    jetbrains.idea-ultimate
    devbox
    git
  ];

  home-manager.users.${username} = {
    programs = {
      neovim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;
      };


      direnv = {
        enable = true;
        nix-direnv.enable = true;
      };


      #   vscode = {
      #      enable=true;
      #        extensions = with pkgs.vscode-extensions; [
      #   dracula-theme.theme-dracula
      #   vscodevim.vim
      #   yzhang.markdown-all-in-one
      #     ms-python.python
      #    ms-vsliveshare.vsliveshare
      # ];
      #   };
    };
  };
}
