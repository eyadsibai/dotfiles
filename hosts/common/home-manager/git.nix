{ pkgs, ... }: {

  home.packages = [ pkgs.tig ];
  programs.gh = {
    enable = true;
    enableGitCredentialHelper = true;
    settings = {
      git_protocol = "ssh";

      prompt = "enabled";

      aliases = {
        co = "pr checkout";
        pv = "pr view";
      };
    };
  };

  programs.git = {
    enable = true;

    # diff tool
    delta = { enable = true; };
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

    # diff tool
    # diff-so-fancy = {
    #   enable = true;
    # };

    # diff tool
    # difftastic = {
    #   enable = true;
    # };

    lfs = { enable = true; };
  };

  programs.gitui = { enable = true; };
  programs.lazygit = { enable = true; };
}
