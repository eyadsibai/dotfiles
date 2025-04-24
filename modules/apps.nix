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
    firefox

    htop
    tmux
    #      unityhub    #  thunderbird
    # nix-index
    #      obs-studio
    spotify

    timg
    # solaar
    ghostty
    lmstudio
    quickemu

    gum
    oterm
    # vllm

  ];
  environment.variables.EDITOR = "nvim";

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };
  # programs.nix-index.enable = true;

  # programs.mtr.enable = true;

}
