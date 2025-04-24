{ lib, ... }:

{
  imports = [
    ./firewall.nix
    ./polkit.nix
  ];

  options.security = {
    # Options are defined in the imported files
    # e.g., security.firewall.enable, security.polkit.enable, etc.
  };
}
