# This file now configures nixvim, based on the Darwin config
{ lib, config, pkgs, username, nixvim, ... }: # Added nixvim input

let
  cfg = config.dev.editors.nixvim;
in
{
  options.dev.editors.nixvim = { # Renamed option path
    enable = lib.mkEnableOption "NixVim configuration";
  };

  config = lib.mkIf cfg.enable {
    # Use the Darwin-compatible pattern for home-manager.users
    home-manager.users = lib.mkIf cfg.enable {
      "${username}" = {
        imports = [ nixvim.homeManagerModules.nixvim ];

        programs.nixvim = {
          enable = true;
          # colorschemes.gruvbox.enable = true;
          colorschemes.catppuccin.enable = true;

          plugins = {
            lightline.enable = true;
            nvim-tree.enable = true;
            gitsigns.enable = true;
            fugitive.enable = true;
            diffview.enable = true;
            neogit.enable = true;
            web-devicons.enable = true;
            telescope.enable = true;
          };

          opts = {
            number = true;
            relativenumber = true;
            shiftwidth = 2;
          };

          # Ensure neovim package is installed if nixvim doesn't handle it
          # (nixvim usually does, but good practice)
          # extraPackages = with pkgs; [ neovim ];

          # Set default editor aliases if desired
          defaultEditor = true;
          vimAlias = true;
        };
      };
    };
  };
}
