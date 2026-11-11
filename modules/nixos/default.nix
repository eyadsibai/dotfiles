# Shared by every NixOS host. Optional pieces (desktop.nix, sunshine.nix,
# virtualisation.nix, ai.nix) are imported by the hosts that want them.
{
  config,
  lib,
  username,
  ...
}:
{
  options.my.server = lib.mkEnableOption ''
    a machine nobody sits at (home-server): no printing, sound or 1Password app,
    and in Home Manager only the shell, CLI tools and SSH. Everything it installs
    has to come from the binary cache or build reliably, because a package that
    fails to build stops its nightly upgrade
  '';

  config.home-manager.users.${username}.imports =
    if config.my.server then
      [
        ../home/shell.nix
        ../home/cli.nix
        ../home/ssh.nix
      ]
    else
      [ ../home ];

  imports = [
    ./nix.nix
    ./users.nix
    ./secrets.nix
    ./1password.nix
    ./base.nix
    ./fonts.nix
    ./ssh.nix
    # Off unless a host turns them on: my.autoUpgrade, my.secureBoot
    ./auto-upgrade.nix
    ./secure-boot.nix
    # The self-hosted CI (my.ci) is parked: kept for later, but not loaded by every
    # host while nothing uses it. docs/ci.md says how to bring it back.
    # ./ci/nixbot.nix
  ];
}
