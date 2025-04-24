{ lib, ... }:

{
  imports = [
    ./zsh.nix
    ./bash.nix
    ./nushell.nix
    ./starship.nix
    ./carapace.nix
    ./cli-tools.nix
    ./yazi.nix # Added yazi
  ];

  options.shell = {
    # Options are defined in the imported files
    # e.g., shell.zsh.enable, shell.starship.enable, shell.cli-tools.enable, etc.
  };
}
