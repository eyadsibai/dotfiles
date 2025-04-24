{ config
, pkgs
, lib
, ...
}: {
  # enable flakes globally
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.keep-outputs = true;
  nix.settings.keep-derivations = true;
  nix.settings.max-jobs = lib.mkDefault 32; # Set this to the number of cores you have
  nix.settings.cores = lib.mkDefault 0; # Use all available cores
  nix.settings.sandbox = true; # Ensure sandboxing is enabled for security and reliability
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.cudaSupport = true;
  # nixpkgs.overlays = [
  #   (final: prev: {
  #     pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [(
  #       python-final: python-prev: {
  #         onnxruntime = python-prev.onnxruntime.overridePythonAttrs (
  #           oldAttrs: {
  #             buildInputs = lib.lists.remove pkgs.onnxruntime oldAttrs.buildInputs;
  #           }
  #         );
  #       }
  #     )];
  #   })
  # ];
  #  nixpkgs.config.cudaCapabilities = ["12.2" "12.3"];
  # Use this instead of services.nix-daemon.enable if you
  # don't wan't the daemon service to be managed for you.
  # nix.useDaemon = true;

  #  nix.package = pkgs.nixFlakes;

  # do garbage collection weekly to keep disk usage low
  nix.gc = {
    automatic = lib.mkDefault true;
    options = lib.mkDefault "--delete-older-than 7d";
  };

  # Disable auto-optimise-store because of this issue:
  #   https://github.com/NixOS/nix/issues/7273
  # "error: cannot link '/nix/store/.tmp-link-xxxxx-xxxxx' to '/nix/store/.links/xxxx': File exists"
  nix.settings = {
    auto-optimise-store = true;
    substituters = [
      "https://cache.nixos.org/"
      "https://ai.cachix.org"
      "https://nix-community.cachix.org"

    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "ai.cachix.org-1:N9dzRK+alWwoKXQlnn0H6aUx0lU/mspIoz8hMvGvbbc="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];


  };


}
