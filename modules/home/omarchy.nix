# Omarchy user session (nixarchy): seeds ~/.config from Omarchy's defaults once,
# then leaves those files editable, as on Arch. Imported by modules/nixos/desktop.nix.
{ inputs, ... }:
{
  imports = [ inputs.nixarchy.homeManagerModules.nixarchy ];

  programs.nixarchy.enable = true;
}
