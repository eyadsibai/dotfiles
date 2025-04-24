{ pkgs, username, hostname, useremail, lib, ... }:
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

  home-manager.users."${username}" = {
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

      # From home/git.nix
      git = {
        enable = true;
        lfs.enable = true;
        userName = "eyadsibai"; # Using the specific username from home/git.nix
        userEmail = useremail; # Using the passed useremail variable
        extraConfig = {
          init.defaultBranch = "master";
          push.autoSetupRemote = true;
          pull.rebase = true;
        };
        delta = {
          enable = false;
          options = {
            features = "side-by-side";
          };
        };
        aliases = {
          br = "branch";
          co = "checkout";
          st = "status";
          ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
          ll = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate --numstat";
          cm = "commit -m";
          ca = "commit -am";
          dc = "diff --cached";
          amend = "commit --amend -m";
          update = "submodule update --init --recursive";
          foreach = "submodule foreach";
        };
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
