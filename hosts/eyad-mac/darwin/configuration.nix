{ config
, lib
, pkgs
, ...
}:
{

  imports = [ ./fonts.nix ./system.nix ];
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

  nix.extraOptions = ''
    auto-optimise-store = true
    experimental-features =  "nix-command" "flakes"
  '' + lib.optionalString (pkgs.system == "aarch64-darwin") ''
    extra-platforms = x86_64-darwin aarch64-darwin
  '';

  homebrew = {
    enable = true;
    autoUpdate = false;
    cleanup = "zap";
    brews = [ "mas" ];
    casks = [ ];
    taps = [ "homebrew/cask-fonts" "mongodb/brew" ];
    masApps = { };
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

  time.timeZone = "Asia/Riyadh";
  services.skhd.enable = true;
  services.spacebar.enable = true;
  services.spotifyd.enable = true;
  services.yabai.enable = true;

}
