# What Home Manager needs when it runs on its own, on a machine whose system another
# distribution owns: the Omarchy on Arch machines (arch.nix) and spark (hosts/spark).
{
  lib,
  pkgs,
  username,
  ...
}:
{
  home.username = username;
  home.homeDirectory = "/home/${username}";
  programs.home-manager.enable = true;
  targets.genericLinux.enable = true; # desktop entries and XDG paths for Nix's apps

  # The caches every machine uses, in ~/.config/nix/nix.conf. The daemon accepts
  # them from me because /etc/nix/nix.conf (arch/nix.conf, kept by scripts/host-system)
  # makes me a trusted user. The package only checks the file at build time; the nix
  # that runs is the one the machine already has (pacman's, or the installer's).
  nix = {
    package = pkgs.nix;
    settings = { inherit (import ../common/caches.nix) substituters trusted-public-keys; };
  };

  home.packages = [ pkgs.nh ];

  # The keys allowed to log in here, the same list the NixOS hosts get (users.nix).
  # Copied, not linked: sshd's StrictModes refuses a file whose real path passes
  # through /nix/store, which is group-writable. Whatever was there before the first
  # switch is kept once as authorized_keys.pre-hm.
  home.activation.authorizedKeys = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    keys="$HOME/.ssh/authorized_keys"
    if ! cmp -s ${../nixos/authorized-keys} "$keys"; then
      run install -d -m700 "$HOME/.ssh"
      if [ -e "$keys" ] && [ ! -e "$keys.pre-hm" ]; then
        run cp -p "$keys" "$keys.pre-hm"
      fi
      run install -m600 ${../nixos/authorized-keys} "$keys"
    fi
  '';
}
