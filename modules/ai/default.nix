{ lib, config, pkgs, username, ... }:

{
  imports = [
    # Import ollama module unconditionally.
    # Its own configuration should determine if it's active.
    ./ollama.nix
  ];

  options.ai = {
    # Options defined in imported files (e.g., ai.ollama.enable)
    lmstudio = {
      enable = lib.mkEnableOption "lmstudio package";
    };
  };

  # Define config unconditionally
  config = {
    # Use lib.optionals for list assignments
    home-manager.users = lib.mkIf config.ai.lmstudio.enable {
      "${username}" = {
        home.packages = with pkgs; [
          lmstudio
        ];
      };
    };
  };
}
