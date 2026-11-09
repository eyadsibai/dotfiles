# Shared by every NixOS host. Optional pieces (desktop.nix, sunshine.nix,
# virtualisation.nix, ai.nix) are imported by the hosts that want them.
{ username, ... }:
{
  home-manager.users.${username}.imports = [ ../home ];

  imports = [
    ./nix.nix
    ./users.nix
    ./secrets.nix
    ./1password.nix
    ./base.nix
    ./fonts.nix
    ./ssh.nix
    # Off unless a host turns them on: my.autoUpgrade, my.secureBoot, my.ci
    ./auto-upgrade.nix
    ./secure-boot.nix
    ./ci/nixbot.nix
  ];
}
