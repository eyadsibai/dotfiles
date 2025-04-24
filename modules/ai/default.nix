{ lib, config, pkgs, username, ... }: {
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
    # environment.systemPackages = with pkgs; [ lmstudio ]; # Moved to HM
    home-manager.users."${username}".home.packages = with pkgs; [
      lmstudio
    ];
  };
}
