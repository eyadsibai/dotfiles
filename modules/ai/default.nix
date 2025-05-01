{ lib, config, pkgs, username, ... }:

{
  imports = [
  ] ++ lib.optionals pkgs.stdenv.hostPlatform.isLinux [
    # Linux-specific modules
    ../ollama.nix
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
