{ config, pkgs, ... }: {

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [

    # CUDA
    # cudaPackages.cudnn
    # (cudaPackages.cudatoolkit.overrideAttrs (oldAttrs: {
    #     cudaVersion = "12.3";
    #   }))

    cachix
    just
    micro
    nixpkgs-fmt
    firefox
    micro

    htop
    tmux
    poetry
    git
    #      unityhub    #  thunderbird
    # nix-index
    #      obs-studio
    spotify
    jetbrains.jdk
    jetbrains.idea-ultimate

    devenv
    devbox
    virtualenv
    timg
    # solaar
    ghostty
    lmstudio
    quickemu

    gum
    oterm
    vscode.fhs
    vllm

  ];
  environment.variables.EDITOR = "nvim";

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  # programs.nix-index.enable = true;

  # programs.mtr.enable = true;

}
