{ pkgs, ... }:
{
  home.packages = with pkgs; [
    nnn # terminal file manager
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
    fzf

    # storage & cloud
    rclone
    ncdu
    awscli2

    # network
    aria2
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
    gnupg
    glow # markdown viewer
  ];

  programs.eza = {
    enable = true;
    git = true;
    icons = "auto";
  };

  # System monitor; built with CUDA support for the NVIDIA GPU panel
  programs.btop = {
    enable = true;
    package = pkgs.btop.override { cudaSupport = true; };
    settings.proc_sorting = "cpu direct";
  };

  programs.skim = {
    enable = true;
    enableBashIntegration = true;
  };
}
