{ inputs
, config
, lib
, pkgs
, ...
}:
{

  imports = [
    ./fonts.nix
    ./system.nix
    ../../common/darwin/yabai
    ../../common/darwin/skhd
  ];
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  users.nix.configureBuildUsers = true;

  nix.trustedUsers = [
    "@admin"
  ];

  # package = pkgs.nixFlakes;

  # nix.settings = {
  #   auto-optimise-store = true;
  #   experimental-features = [ "nix-command" "flakes" ];
  # };


  nix = {
    package = pkgs.nixFlakes;
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: { flake = value; }) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${ key }=${ value.to.path }") config.nix.registry;

    gc = {
      # Garbage collection
      automatic = true;
      interval.Day = 7;
      options = "--delete-older-than 7d";
    };

    extraOptions = ''
      auto-optimise-store = true
      experimental-features =  nix-command flakes
    '' + lib.optionalString (pkgs.system == "aarch64-darwin") ''
      extra-platforms = x86_64-darwin aarch64-darwin
    '';
  };
  # Create /etc/bashrc that loads the nix-darwin environment.
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    enableCompletion = true;
    enableFzfCompletion = true;
    enableSyntaxHighlighting = true;
  };
  programs.tmux.enable = true;

  #  services.mopidy.enable = true;

  # Add ability to used TouchID for sudo authentication
  # security.pam.enableSudoTouchIdAuth = true;
  # programs.fish.enable = true;
  networking = {
    computerName = "eyad-mac";
    hostName = "eyad-mac";
    localHostName = "eyad-mac";
  };
  environment.systemPackages = with pkgs; [

  ];

  # https://github.com/nix-community/home-manager/issues/423
  environment.variables = {
    TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";

  };

  programs.nix-index.enable = true;

  # time.timeZone = "Asia/Riyadh";
  services.spacebar.enable = true;
  services.spacebar.package = pkgs.spacebar;
  services.spotifyd.enable = true;


  users.users.eyad = {
    shell = pkgs.zsh;
  };
}
