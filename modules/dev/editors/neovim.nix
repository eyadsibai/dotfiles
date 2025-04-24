{ lib, config, pkgs, username, ... }:

let
  cfg = config.dev.editors.neovim;
in
{
  options.dev.editors.neovim = {
    enable = lib.mkEnableOption "Neovim configuration";
  };

  config = lib.mkIf cfg.enable {
    # Neovim package could be added here if not managed elsewhere
    # environment.systemPackages = with pkgs; [ neovim ];

    home-manager.users."${username}" = {
      programs.neovim = {
        enable = true;
        defaultEditor = true;
        vimAlias = true;
        # Add further neovim config here
      };
    };
  };
}
