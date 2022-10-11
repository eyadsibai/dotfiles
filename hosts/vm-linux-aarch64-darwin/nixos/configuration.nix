{ inputs, config, username, pkgs, lib, modulesPath, ... }:

{
  imports = [
    inputs.macos-builder.nixosModules.aarch64-darwin.default
  ];

  system.stateVersion = "22.05";

  home-manager.users.${username} = {

    home.stateVersion = "22.05";

  };


  # # Configure networking
  networking.useDHCP = false;
  networking.interfaces.eth0.useDHCP = true;

  # # Create user
  services.getty.autologinUser = "${username}";
  users.users.${username} = { isNormalUser = true; extraGroups = [ "wheel" ]; };

  # # Enable paswordless ‘sudo’ for the "username" user
  security.sudo.wheelNeedsPassword = false;

  # # Make it output to the terminal instead of separate window
  # virtualisation = { graphics = false; useNixStoreImage = true; writableStore = true; };


  nixpkgs.hostPlatform = "aarch64-linux";


  # DNS fails for QEMU user networking (SLiRP) on macOS.  See:
  #
  # https://github.com/utmapp/UTM/issues/2353
  #
  # This works around that by using a public DNS server other than the
  # DNS server that QEMU provides (normally 10.0.2.3)
  networking.nameservers = [ "8.8.8.8" ];
  # nix.settings = {
  #   auto-optimise-store = true;
  #   trusted-users = [ "root" "builder" ];
  #   services.openssh.enable = true;

  # };

  # nix = {
  # settings = {
  # builders = "ssh-ng://builder@localhost aarch64-linux /etc/nix/nixbld_ed25519 - - - - c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpCV2N4Yi9CbGFxdDFhdU90RStGOFFVV3JVb3RpQzVxQkorVXVFV2RWQ2Igcm9vdEBuaXhvcwo=";

  # Not strictly necessary, but this will reduce your disk utilization
  # builders-use-substitutes = true;
  # };
  # };
  # virtualisation = {

  #   forwardPorts = [
  #     { from = "host"; guest.port = 22; host.port = 22; }
  #   ];

  #   # Disable graphics for the builder since users will likely want to
  #   # run it non-interactively in the background.
  #   graphics = false;

  #   # If we don't enable this option then the host will fail to delegate
  #   # builds to the guest, because:
  #   #
  #   # - The host will lock the path to build
  #   # - The host will delegate the build to the guest
  #   # - The guest will attempt to lock the same path and fail because
  #   #   the lockfile on the host is visible on the guest
  #   #
  #   # Snapshotting the host's /nix/store as an image isolates the guest
  #   # VM's /nix/store from the host's /nix/store, preventing this
  #   # problem.
  #   useNixStoreImage = true;

  #   # Obviously the /nix/store needs to be writable on the guest in
  #   # order for it to perform builds.
  #   writableStore = true;

  #   # This ensures that anything built on the guest isn't lost when the
  #   # guest is restarted.
  #   writableStoreUseTmpfs = false;

  # };

  # done in lib mkNixOSSystem
  # virtualisation.host.pkgs = nixpkgs.legacyPackages."${system}";
  virtualisation.graphics = false;
  virtualisation.useNixStoreImage = true;
  virtualisation.writableStore = true;
}
