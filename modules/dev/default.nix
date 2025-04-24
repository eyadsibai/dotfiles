{ lib, ... }:

{
  imports = [
    ./git.nix
    ./editors/nixvim.nix
    ./editors/helix.nix
    ./editors/kakoune.nix # Added kakoune
    ./languages/java.nix
    ./tools/direnv.nix
    ./tools/nix.nix
    ./tools/make.nix
    ./tools/devbox.nix
    ./tools/idea.nix
    ./envfs.nix
  ];

  options.dev = {
    # Options are defined in the imported files
    # e.g., dev.git.enable, dev.editors.nixvim.enable, dev.editors.helix.enable, dev.editors.kakoune.enable, etc.
  };
}
