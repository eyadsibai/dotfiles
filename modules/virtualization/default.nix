{ lib, ... }:

{
  imports = [
    ./libvirt.nix
    ./docker.nix
  ];

  options.virtualization = {
    # Options are defined in the imported files
    # e.g., virtualization.libvirt.enable, virtualization.docker.enable, etc.
  };
}
