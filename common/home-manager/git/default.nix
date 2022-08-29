{ pkgs
, config
, ...
}:
{
  home.packages = [ pkgs.tig ];
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
    userEmail = builtins.concatStringsSep "@" [ "eyad.alsibai" "gmail.com" ];
    # diff tool
    delta = {
      enable = true;
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
