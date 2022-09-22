{ config, pkgs, lib, modulesPath, username, ... }:

{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];


  # # Configure networking
  # networking.useDHCP = false;
  # networking.interfaces.eth0.useDHCP = true;

  # # Create user
  # services.getty.autologinUser = "${username}";
  # users.users.${username} = { isNormalUser = true; extraGroups = [ "wheel" ]; };

  # # Enable paswordless ‘sudo’ for the "username" user
  # security.sudo.wheelNeedsPassword = false;

  # # Make it output to the terminal instead of separate window
  # virtualisation = { graphics = false; useNixStoreImage = true; writableStore = true; };


  # DNS fails for QEMU user networking (SLiRP) on macOS.  See:
  #
  # https://github.com/utmapp/UTM/issues/2353
  #
  # This works around that by using a public DNS server other than the
  # DNS server that QEMU provides (normally 10.0.2.3)
  networking.nameservers = [ "8.8.8.8" ];

  nixpkgs.hostPlatform = "aarch64-linux";

  environment.etc = {
    "ssh/ssh_host_ed25519_key" = {
      mode = "0600";

      source = ./keys/ssh_host_ed25519_key;
    };

    "ssh/ssh_host_ed25519_key.pub" = {
      mode = "0644";

      source = ./keys/ssh_host_ed25519_key.pub;
    };
  };

  nix.settings = {
    auto-optimise-store = true;

    min-free = 1024 * 1024 * 1024;

    max-free = 3 * 1024 * 1024 * 1024;

    trusted-users = [ "root" "builder" ];
  };

  services.openssh.enable = true;

  system.stateVersion = "22.05";

  users.users.builder = {
    isNormalUser = true;

    openssh.authorizedKeys.keyFiles = [ ./keys/nixbld_ed25519.pub ];
  };

  virtualisation = {
    diskSize = 20 * 1024;

    forwardPorts = [
      { from = "host"; guest.port = 22; host.port = 22; }
    ];

    # Disable graphics for the builder since users will likely want to
    # run it non-interactively in the background.
    graphics = false;

    # If we don't enable this option then the host will fail to delegate
    # builds to the guest, because:
    #
    # - The host will lock the path to build
    # - The host will delegate the build to the guest
    # - The guest will attempt to lock the same path and fail because
    #   the lockfile on the host is visible on the guest
    #
    # Snapshotting the host's /nix/store as an image isolates the guest
    # VM's /nix/store from the host's /nix/store, preventing this
    # problem.
    useNixStoreImage = true;

    # Obviously the /nix/store needs to be writable on the guest in
    # order for it to perform builds.
    writableStore = true;

    # This ensures that anything built on the guest isn't lost when the
    # guest is restarted.
    writableStoreUseTmpfs = false;

  };
}
