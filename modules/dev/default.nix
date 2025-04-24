{ lib, ... }:

{
  imports = [
    ./git.nix
    ./editors/neovim.nix
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
    # e.g., dev.git.enable, dev.editors.neovim.enable, etc.
  };
}
