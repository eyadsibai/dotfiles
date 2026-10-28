{
  lib,
  pkgs,
  useremail,
  ...
}:
let
  prettyLog = "log --pretty=format:\"%C(yellow)%h%Cred%d\\\\ %Creset%s%Cblue\\\\ [%cn]\" --decorate";
in
{
  home.packages =
    with pkgs;
    [
      gnumake
      nil
      nixd
      devenv # per-project environments: devenv.nix + `use devenv` in .envrc
    ]
    # JetBrains' JDK is built for Linux only
    ++ lib.optional stdenv.hostPlatform.isLinux jetbrains.jdk;

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
      github.user = "eyadsibai";
      init.defaultBranch = "master";
      push = {
        default = "current";
        autoSetupRemote = true;
      };
      pull.rebase = true;
      rebase.autoStash = true;
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
    ];
  };

  # Claude Code from nixpkgs (updated with `just update`; the built-in auto-updater is off).
  # Settings stay in ~/.claude/settings.json, writable by Claude Code itself.
  programs.claude-code.enable = true;

  programs.gh = {
    enable = true;
    gitCredentialHelper.enable = true;
    settings = {
      git_protocol = "ssh";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
    extensions = [ pkgs.gh-dash ]; # `gh dash`: PRs and issues dashboard
  };
}
