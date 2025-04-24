# Just is a command runner, Justfile is very similar to Makefile, but simpler.

############################################################################
#
#  Darwin related commands (Update hostname if needed)
#
############################################################################

DARWIN_HOSTNAME := "macbook" # Set your Darwin hostname here

darwin:
  nix build .#darwinConfigurations.{{DARWIN_HOSTNAME}}.system \
    --extra-experimental-features 'nix-command flakes'
  ./result/sw/bin/darwin-rebuild switch --flake .#{{DARWIN_HOSTNAME}}

darwin-debug:
  nix build .#darwinConfigurations.{{DARWIN_HOSTNAME}}.system --show-trace --verbose \
    --extra-experimental-features 'nix-command flakes'
  ./result/sw/bin/darwin-rebuild switch --flake .#{{DARWIN_HOSTNAME}} --show-trace --verbose

############################################################################
#
#  NixOS related commands (Update hostname if needed)
#
############################################################################

NIXOS_HOSTNAME := "workstation" # Set your NixOS hostname here

nixos:
  sudo nixos-rebuild switch --flake .#{{NIXOS_HOSTNAME}}

nixos-debug:
  sudo nixos-rebuild switch --flake .#{{NIXOS_HOSTNAME}} --show-trace --verbose

############################################################################
#
#  Nix related commands
#
############################################################################

update:
  nix flake update

# Note: NixOS system profile history/wipe is usually managed by nixos-rebuild generations
# history:
#   nix profile history --profile /nix/var/nix/profiles/system

gc:
  # Garbage collect all unused nix store entries
  # Use 'sudo' on NixOS if needed, not needed on Darwin usually
  nix store gc --debug

fmt:
  # Format the nix files in this repo using Alejandra (defined in flake.nix)
  nix fmt

clean:
  rm -rf result* # Clean build results for both OSes
