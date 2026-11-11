# Omarchy user session (nixarchy): seeds ~/.config from Omarchy's defaults once,
# then leaves those files editable, as on Arch. Imported by modules/nixos/desktop.nix.
{ inputs, ... }:
{
  imports = [ inputs.nixarchy.homeManagerModules.nixarchy ];

  programs.nixarchy.enable = true;
  programs.neovim.enable = false; # Omarchy's Neovim and LazyVim (see dev.nix)

  # nixarchy's beginner guide (tour card, manual search, AI tutor). Off: its codex-acp
  # pulls in codex, which nixpkgs can't serve from cache and so compiles here on every
  # update, with about 3 GB of downloads.
  services.nixi.enable = false;
}
