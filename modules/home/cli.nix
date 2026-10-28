{ pkgs, ... }:
{
  home.packages = with pkgs; [
    micro
    tmux
    just
    gum
    timg # images in the terminal
    cachix

    # archives
    zip
    xz
    unzip
    p7zip
    zstd

    # search & data
    ripgrep
    jq
    yq-go

    # storage & cloud
    rclone
    ncdu
    awscli2

    # network
    socat
    nmap
    caddy

    # misc
    cowsay
    file
    which
    tree
    gnused
    gnutar
    gawk
    glow # markdown viewer
  ];

  programs.fzf.enable = true;

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  programs.btop = {
    enable = true;
    settings.proc_sorting = "cpu direct";
  };

  programs.skim = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.nnn = {
    enable = true;
    bookmarks = {
      D = "~/Downloads";
      p = "~/dev";
      c = "~/.config";
    };
    plugins = {
      src =
        (pkgs.fetchFromGitHub {
          owner = "jarun";
          repo = "nnn";
          rev = "v4.9";
          sha256 = "sha256-g19uI36HyzTF2YUQKFP4DE2ZBsArGryVHhX79Y0XzhU=";
        })
        + "/plugins";
      mappings = {
        p = "preview-tui";
        o = "fzopen";
      };
    };
  };

  programs.aria2 = {
    enable = true;
    settings = {
      max-connection-per-server = 4;
      split = 4;
      min-split-size = "1M";
      disk-cache = "64M";
      file-allocation = "falloc";
      continue = true;
      max-concurrent-downloads = 5;
    };
  };
}
