# Shared by every Mac (nix-darwin)
{ username, ... }:
{
  home-manager.users.${username}.imports = [
    ../home
    ./home.nix
  ];

  imports = [
    ./nix.nix
    ./system.nix
    ./homebrew.nix
    ./apps.nix
    ./dev-tools.nix
    ./utm.nix
  ];
}
