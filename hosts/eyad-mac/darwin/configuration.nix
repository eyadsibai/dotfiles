{ inputs
, config
, lib
, pkgs
, ...
}:


{

  imports = [
    ../../common/system
    ../../common/system/darwin
    ./fonts.nix
    ./system.nix
    ./nix.nix
    ../../../common/darwin/wm


  ];
  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  services.activate-system.enable = true;
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
    firefox-bin

  ];

  # https://github.com/nix-community/home-manager/issues/423
  environment.variables = {
    TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
  };

  programs.nix-index.enable = true;

  # time.timeZone = "Asia/Riyadh";

  services.spotifyd.enable = true;

  users.users.eyad = {
    shell = pkgs.zsh;
  };
}
