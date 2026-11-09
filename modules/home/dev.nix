# On Arch, pacman owns the programs (arch/<host>.packages) and this sets only their
# config; Nix still installs its own tooling there (nil, nixd, devenv) and Claude Code.
{
  config,
  inputs,
  lib,
  pkgs,
  useremail,
  isArch,
  ...
}:
let
  coderabbit = pkgs.callPackage ../../pkgs/coderabbit.nix { };
  pacmanBin = import ./pacman-bin.nix pkgs;
  prettyLog = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
in
{
  imports = [ inputs.direnv-instant.homeModules.direnv-instant ];

  home.packages =
    with pkgs;
    [
      nil
      nixd
      devenv # per-project environments: devenv.nix + `use devenv` in .envrc
    ]
    # On Arch: make from base-devel, coderabbit from its own installer (~/.local/bin),
    # codex from mise, and the rest from pacman
    ++ lib.optionals (!isArch) [
      gnumake
      coderabbit # `coderabbit`/`cr`: AI review of local changes
    ]
    # JetBrains' JDK is built for Linux only
    ++ lib.optional (stdenv.hostPlatform.isLinux && !isArch) jetbrains.jdk
    # The Macs get codex from Homebrew and uv from modules/darwin/apps.nix
    ++ lib.optionals (stdenv.hostPlatform.isLinux && !isArch) [
      codex # replaces Omarchy's "codex is not installed" stub
      uv
      beads # `bd`: git-backed issue tracker for agents
      dolt # the database beads stores issues in
      trash-cli # `trash`: delete to the freedesktop trash instead of rm
    ];

  # The module wraps its own Neovim; on Arch, Omarchy's LazyVim runs pacman's nvim,
  # and the editor variable and alias are set by hand below
  home.sessionVariables.EDITOR = lib.mkIf isArch "nvim";
  home.shellAliases.vim = lib.mkIf isArch "nvim";
  programs.neovim = {
    enable = lib.mkDefault (!isArch); # omarchy.nix turns it off for Omarchy on NixOS
    defaultEditor = true;
    vimAlias = true;
    # keep pre-26.05 behaviour
    withRuby = true;
    withPython3 = true;
  };

  programs.direnv = {
    enable = true;
    package = lib.mkIf isArch (pacmanBin {
      bin = "direnv";
      from = pkgs.direnv;
    });
    nix-direnv.enable = true;
  };
  # Takes over direnv's shell hooks: the .envrc loads in the background and the
  # prompt comes back at once (inside tmux, a pane shows a slow load's progress)
  programs.direnv-instant.enable = true;

  # Pager for diff, log, show and `git add -p`
  programs.delta = {
    enable = true;
    package = lib.mkIf isArch (pacmanBin {
      bin = "delta";
      from = pkgs.delta;
    });
    enableGitIntegration = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "ansi"; # follows the terminal's Omarchy theme colours
    };
  };

  programs.git = {
    enable = true;
    package = lib.mkIf isArch null;
    lfs = {
      enable = true;
      package = lib.mkIf isArch null;
    };
    settings = {
      user.name = "eyadsibai";
      user.email = useremail;
      github.user = "eyadsibai";
      init.defaultBranch = "master";
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      pull.rebase = true;
      rebase.autoStash = true;
      merge.conflictStyle = "zdiff3"; # conflicts show the common ancestor too
      diff.colorMoved = "default";
      apply.whitespace = "fix";
      help.autocorrect = "prompt";
      feature.manyFiles = true;
      # `git clone gh:owner/repo`, `gst:<id>`
      url."git@github.com:".insteadOf = "gh:";
      url."git@gist.github.com:".insteadOf = "gst:";
      alias = {
        br = "branch";
        co = "checkout";
        ci = "commit";
        st = "status";
        df = "diff";
        ls = prettyLog;
        ll = "${prettyLog} --numstat";
        cm = "commit -m";
        ca = "commit -am";
        dc = "diff --cached";
        amend = "commit --amend -m";
        update = "submodule update --init --recursive";
        foreach = "submodule foreach";

        # history
        l1 = "log --graph";
        l2 = "log --stat --no-merges";
        l3 = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        all = "log --pretty=oneline --abbrev-commit --all --no-merges";
        me = "config user.email";
        today = "!git all --since='12am' --committer=\"$(git me)\"";
        last = "show --name-status";
        changes = "diff --name-status -r";
        diffstat = "diff --stat -r";
        lasttag = "describe --tags --abbrev=0";
        peeps = "!git log --pretty=format:'%Cblue%aN%Creset' --no-merges | sort | uniq -c | sort -rn";

        # undo and reset
        undo = "reset --soft HEAD^";
        r = "reset";
        r1 = "reset HEAD^";
        rh = "reset --hard";
        rh1 = "reset HEAD^ --hard";
        save = "!git commit -am 'save game'";
        credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";

        # conflicts
        ours = "!f() { git checkout --ours \"$@\" && git add \"$@\"; }; f";
        theirs = "!f() { git checkout --theirs \"$@\" && git add \"$@\"; }; f";

        # stash
        sl = "stash list";
        sa = "stash apply";
        ss = "stash push";

        # files and repo
        top = "rev-parse --show-toplevel";
        f = "!git ls-files | grep -i";
        dirty = "!git status --porcelain -uno | wc -l";
        assume = "update-index --assume-unchanged";
        unassume = "update-index --no-assume-unchanged";
        assumed = "!git ls-files -v | grep ^h | cut -c 3-";
        la = "!git config --get-regexp '^alias\\.' | cut -c 7-";

        # remotes and branches
        fp = "fetch --prune";
        up = "pull --ff-only --all -p";
        rso = "remote show origin";
        prune-all = "!git remote | xargs -n 1 git remote prune";
        cleanup-local = "!git branch --merged | grep -vE '^\\*|^\\s*(master|main|develop)$' | xargs -rn 1 git branch -d";
        unfuck = "!git fsck && git remote prune origin && git gc";
      };
    };
    ignores = [
      ".direnv"
      ".vscode"
      ".DS_Store"
      "Thumbs.db"
      "ehthumbs.db"
      "Icon?"
      "*.swp"
      "*.swo"
      "**/.claude/.cc-writes/"
      "**/.claude/settings.local.json"
    ];
  };

  # Claude Code from nixpkgs (updated with `just update`; the built-in auto-updater is off).
  # Settings stay in ~/.claude/settings.json, writable by Claude Code itself.
  programs.claude-code.enable = true;

  programs.gh = {
    enable = true;
    package = lib.mkIf isArch (pacmanBin {
      bin = "gh";
      from = pkgs.gh;
    });
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
    # `gh dash`: PRs and issues dashboard (on Arch, pacman's gh-dash-bin, linked below)
    extensions = lib.optional (!isArch) pkgs.gh-dash;
  };

  # gh runs an extension from ~/.local/share/gh/extensions/gh-<name>/gh-<name>
  xdg.dataFile."gh/extensions/gh-dash/gh-dash" = lib.mkIf isArch {
    source = config.lib.file.mkOutOfStoreSymlink "/usr/bin/gh-dash";
  };
}
