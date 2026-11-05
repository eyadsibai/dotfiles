# Omarchy user session (nixarchy): seeds ~/.config from Omarchy's defaults once,
# then leaves those files editable, as on Arch. Imported by modules/nixos/desktop.nix.
{ inputs, ... }:
{
  imports = [ inputs.nixarchy.homeManagerModules.nixarchy ];

  programs.nixarchy.enable = true;
  programs.neovim.enable = false; # Omarchy's Neovim and LazyVim (see dev.nix)
}
