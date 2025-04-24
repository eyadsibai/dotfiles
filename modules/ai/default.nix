{ lib, config, pkgs, ... }: {
  imports = [
    ./ollama.nix
  ];

  options.ai = {
    # Options defined in imported files (e.g., ai.ollama.enable)
    lmstudio = {
      enable = lib.mkEnableOption "lmstudio package";
    };
  };

  config = lib.mkIf config.ai.lmstudio.enable {
    # AI related packages and configurations
    environment.systemPackages = with pkgs; [
      lmstudio
    ];
  };
}
