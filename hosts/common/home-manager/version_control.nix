{ pkgs
, config
, ...
}:
{
  home.packages = [ pkgs.tig pkgs.legit ];
  programs.gh = {
    enable = config.programs.git.enable;
    enableGitCredentialHelper = true;
    settings = {
      git_protocol = "ssh";
      prompt = "enabled";
      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
      editor = "";
    };

    # to package later
    # https://github.com/seachicken/gh-poi
    # https://github.com/k1LoW/gh-grep
    # https://github.com/gennaro-tedesco/gh-s
    # https://github.com/gennaro-tedesco/gh-i
    extensions = [ pkgs.gh-eco pkgs.gh-dash pkgs.gh-ost pkgs.gh-cal ];

  };
  programs.git = {
    enable = true;
    userName = "eyadsibai";
    userEmail = builtins.concatStringsSep "@" [ (builtins.concatStringsSep "." [ "eyad" "alsibai" ]) "gmail.com" ];
    # diff tool
    delta = {
      enable = false;
    };
    attributes = [
      "* text=auto"
      "*.sh text eol=lf"
      "*.7z filter=lfs diff=lfs merge=lfs -text"
      "*.br filter=lfs diff=lfs merge=lfs -text"
      "*.gz filter=lfs diff=lfs merge=lfs -text"
      "*.tar filter=lfs diff=lfs merge=lfs -text"
      "*.zip filter=lfs diff=lfs merge=lfs -text"
      "*.pdf filter=lfs diff=lfs merge=lfs -text"
      "*.gif filter=lfs diff=lfs merge=lfs -text"
      "*.ico filter=lfs diff=lfs merge=lfs -text"
      "*.jpg filter=lfs diff=lfs merge=lfs -text"
      "*.pdf filter=lfs diff=lfs merge=lfs -text"
      "*.png filter=lfs diff=lfs merge=lfs -text"
      "*.psd filter=lfs diff=lfs merge=lfs -text"
      "*.webp filter=lfs diff=lfs merge=lfs -text"
      "*.woff2 filter=lfs diff=lfs merge=lfs -text"
      "*.exe filter=lfs diff=lfs merge=lfs -text"
    ];
    aliases =
      {
        st = "status";
        branches = "!legit branches";
        br = "branch";
        me = "config user.email";
        rso = " remote show origin";

        # log aliases
        log-branch = "log origin/master..";
        blog = "!git log-branch";
        mlog = "!git log --committer=\"`git me`\"";

        undo-commit = "reset --soft HEAD^";


        # creates a diff of current branch against supplied branch, usage: git export-branch [refbranch]
        branch-name = "!git for-each-ref --format='%(refname:short)' `git symbolic-ref HEAD`";
        export-branch = "!git format-patch --stdout $1 > ~/branches/`git branch-name`.diff";


        # all commits that aren't merges on all branches
        all = "!git log --pretty=oneline --abbrev-commit --all --no-merges";

        # all commits today for only me
        today = "!git all --since='12am' --committer=\"`git me`\"";

        # today's commits without formatting or paging
        today-text = "!git --no-pager today --no-color";

        # files different from master on current branch
        fdm = "!git diff origin/master... --name-status";

        # last commit info in svn style
        last = "!git show --name-status";
        last-files = "!git last --pretty=format:\"\"";

        # last commit only certain type of modification
        mlast = "!git last-files | awk 'match($1, /M/) {print $2}'";
        alast = "!git last-files | awk 'match($1, /A/) {print $2}'";
        dlast = "!git last-files | awk 'match($1, /D/) {print $2}'";



        # `git lint`


        # `git spawn my-new-branch`
        # make new branch based on master no matter which branch is checked out
        spawn = "!sh -c 'git checkout -b $1 \${2-master} && git config branch.$1.localmerge \${2-master}' -";

        # `git nuke my-old-branch`
        # (Checks out master and does a non-forced delete on the branch entered)
        nuke = "!git co master && sh -c 'git br -d $1' -";

        # `git sync`
        # update current branch and master
        # sync = ''
        #       !git update && \
        #   		git co master && \
        #   		git pull && \
        #   		git co @{-1}
        # '';

        # `git save`
        # saves a commit in current branch: local branches you will be rebasing
        save = "!git commit -am \"save game\"";

        # attempt to cleanup some common problems
        unfuck = "!git fsck && git remote prune origin && git gc";

        # find the top level of current repository
        top = "!git rev-parse --show-toplevel";

        # list files changed by last commit in absolute location
        list = "!git show --pretty=format:\" \" --name-only | sed '/^$/d' | sed \"s|^|`git top`/|g\"";

        # give a count of dirty files
        dirty = "!git status --porcelain -uno | wc -l";

        # number of non-merge commits
        peeps = "!git log --pretty=format:\"%Cblue%aN%Creset \" --no-merges | sort | uniq -c | sort -rn";
        mergers = "!git log --pretty=format:\"%Cred%aN%Creset \" --merges | sort | uniq -c | sort -rn";


        # update current branch
        update = "!sh -c 'git fetch origin && git rebase -p origin/\${1-master}' -";

        co = "checkout";
        ci = "commit";
        df = "diff";
        mod = "submodule";
        fp = "fetch --prune";
        l1 = "log --graph";
        l3 = "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit --date=relative";
        ls = "log --pretty=format:\"%C(yellow)%h%Cred%d\\ %Creset%s%Cblue\\ [%cn]\" --decorate";
        l2 = "log --stat --no-merges";
        l4 = "log --graph --pretty=format:'%Cred%h%Creset %an -%C(yellow)%d%Creset %s %Cgreen(%cr)%Creset' --abbrev-commit --date=relative";
        changes = "diff --name-status -r";
        diffstat = "diff --stat -r";
        undo = "reset --soft HEAD^";
        merge-dry = ''
              !f() { git merge-tree `git merge-base $2 $1` $2 $1;};
          f
        ''; #check how the merge of dev into master will go: git dry dev master
        merge-wet = "!f() { git merge --no-commit --no-ff $1; }; f";
        new = "!sh -c 'git log $1@{1}..$1@{0} \"$@\"'";
        prune-all = "!git remote | xargs -n 1 git remote prune";
        up = "pull --ff-only --all -p";
        gra = ''
          !f() { A = $(pwd) && TOPLEVEL=$(git rev-parse --show-toplevel) && cd $TOPLEVEL && git grep --full-name -In $1 | xargs -I{} echo $TOPLEVEL/{} && cd $A;
          };
          f
        '';
        grep = "grep -Ii";
        f = "!git ls-files | grep -i";
        la = "!git config -l | grep alias | cut -c 7-";
        assume = "update-index --assume-unchanged";
        unassume = "update-index --no-assume-unchanged";
        assumed = "!git ls-files -v | grep ^h | cut -c 3-";
        unassumeall = "!git assumed | xargs git update-index --no-assume-unchanged";
        assumeall = "!git st -s | awk {'print $2'} | xargs git assume";
        lasttag = "describe --tags --abbrev=0";
        ours = "!f() { git co --ours $@ && git add $@; }; f";
        theirs = "!f() { git co --theirs $@ && git add $@; }; f";
        diff = "diff --word-diff";
        dc = "diff --cached";
        r = "reset";
        r1 = "reset HEAD^";
        r2 = "reset HEAD^^";
        rh = "reset --hard";
        rh1 = "reset HEAD^ --hard";
        rh2 = "reset HEAD^^ --hard";
        sl = "stash list";
        sa = "stash apply";
        ss = "stash save";
        dl = "!git ll -1";
        dlc = "diff --cached HEAD^";
        branch-dates = "
            !f() { git for-each-ref --sort = committerdate refs/\${1:-heads}/ - -format='%(committerdate:short)\t%(authorname)\t%(refname:short)' | sed 's_origin/__g' | column -t -s'    ';
          } ; f";
        # Credit an author on the latest commit
        credit = "!f() { git commit --amend --author \"$1 <$2>\" -C HEAD; }; f";
        graft = "!legit graft";
        harvest = "!legit harvest";
        publish = "!legit publish";
        unpublish = "!legit unpublish";
        sprout = "!legit sprout";
        sync = "!legit sync";
        switch = "!legit switch";
        resync = "!legit resync";
        cleanup-local = "!git branch --merged | grep  -v '\\*\\|master\\|develop' | xargs -n 1 git branch -d";
        # cleanup-origin = "!git branch -r --merged | grep -v master | sed 's/origin\///' | xargs -n 1 git push --delete origin"
      };
    ignores = [
      ".direnv"
      ".vscode"
      ".DS_Store"
      "ehthumbs.db"
      "Icon?"
      "Thumbs.db"
      "2*~"
      "*.swp"
      "*.swo"
    ];

    extraConfig = { color = { ui = "auto"; }; };
    # push.useBitmaps = false;

    # diff tool
    # diff-so-fancy = {
    #   enable = true;
    # };
    # diff tool
    # difftastic = {
    #   enable = true;
    # };
    lfs = {
      enable = true;
    };
  };
  programs.gitui = { enable = config.programs.git.enable; };
  programs.lazygit = { enable = config.programs.git.enable; };
}
