{ lib, config, pkgs, username, useremail, ... }:

let
  cfg = config.dev.git;
in
{
  options.dev.git = {
    enable = lib.mkEnableOption "Git configuration";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      git
    ];

    home-manager.users."${username}" = {
      programs.git = {
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
    };
  };
}
