{ pkgs, useremail, ... }:
let
  prettyLog = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
in
{
  home.packages = with pkgs; [
    gnumake
    nil
    nixd
    devenv # per-project environments: devenv.nix + `use devenv` in .envrc
    jetbrains.jdk
  ];

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    # keep pre-26.05 behaviour
    withRuby = true;
    withPython3 = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.git = {
    enable = true;
    lfs.enable = true;
    settings = {
      user.name = "eyadsibai";
      user.email = useremail;
      init.defaultBranch = "master";
      push.autoSetupRemote = true;
      pull.rebase = true;
      alias = {
        br = "branch";
        co = "checkout";
        st = "status";
        ls = prettyLog;
        ll = "${prettyLog} --numstat";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        amend = "commit --amend -m";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";
      };
    };
  };

  # Claude Code from nixpkgs (updated with `just update`; the built-in auto-updater is off).
  # Settings stay in ~/.claude/settings.json, writable by Claude Code itself.
  programs.claude-code.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings.git_protocol = "ssh";
  };
}
