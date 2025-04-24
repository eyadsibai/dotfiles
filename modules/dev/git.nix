{ lib, config, pkgs, username, useremail, ... }:

let
  cfg = config.dev.git;
in
{
  options.dev.git = {
    enable = lib.mkEnableOption "Git configuration";
    includeWorkConfig = lib.mkEnableOption "Include work-specific git config (~/work/.gitconfig)";
    delta = {
      enable = lib.mkEnableOption "Enable git delta";
    };
  };

  config = lib.mkIf cfg.enable {
    # Ensure HM generated config is used
    home.activation.removeExistingGitconfig = lib.hm.dag.entryBefore [ "checkLinkTargets" ] ''
      rm -f ~/.gitconfig
    '';

    environment.systemPackages = with pkgs; [
      git
    ];

    home-manager.users."${username}" = {
      programs.git = {
        enable = true;
        lfs.enable = true;
        userName = "eyadsibai"; # Using the specific username from home/git.nix
        userEmail = useremail; # Using the passed useremail variable

        includes = lib.mkIf cfg.includeWorkConfig [
          {
            path = "~/work/.gitconfig";
            condition = "gitdir:~/work/";
          }
        ];

        extraConfig = {
          init.defaultBranch = "master";
          push.autoSetupRemote = true;
          pull.rebase = true;
        };

        delta = {
          enable = cfg.delta.enable; # Use option
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
