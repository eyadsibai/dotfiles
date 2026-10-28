# Shared by every Mac (nix-darwin)
{
  imports = [
    ./nix.nix
    ./system.nix
    ./homebrew.nix
    ./apps.nix
    ./dev-tools.nix
    ./utm.nix
  ];
}
