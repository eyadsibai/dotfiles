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
    # Add git to system packages
    environment.systemPackages = with pkgs; [
      git
    ];

    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        # Instead of using lib.hm.dag which isn't available here,
        # we'll use a simple initialization script
        # home.sessionVariables = {
        #   # This is a dummy variable to ensure the command runs
        #   GIT_CONFIG_CLEANED = builtins.toString (builtins.derivation {
        #     name = "clean-gitconfig";
        #     system = pkgs.system;
        #     builder = pkgs.writeShellScript "clean-gitconfig.sh" ''
        #       rm -f ~/.gitconfig
        #       touch $out
        #     '';
        #   });
        # };

        programs.git = {
          enable = true;
          lfs.enable = true;
          userName = "eyadsibai"; # Using the specific username from home/git.nix
          userEmail = useremail; # Using the passed useremail variable

          includes = lib.optionals cfg.includeWorkConfig [
            # Use optionals for lists
            {
              path = "~/dev/.gitconfig";
              condition = "gitdir:~/dev/";
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
  };
}
