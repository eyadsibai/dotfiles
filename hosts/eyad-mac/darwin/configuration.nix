{ inputs
, config
, lib
, pkgs
, hostname
, username
, ...
}:
{

  imports = [
    ./nix.nix
    ../../common/optional/darwin/wm

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
  programs.fish.enable = true;

  environment.systemPackages = with pkgs; [
    firefox-darwin.firefox-bin
  ];

  # https://github.com/nix-community/home-manager/issues/423
  environment.variables = {
    TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
  };

  programs.nix-index.enable = true;

  time.timeZone = "Asia/Riyadh";

  # services.spotifyd.enable = true;
  #
  users.users.${username} = {
    #   name = "${username}";
    home = "/Users/${username}";
    #   shell = pkgs.fish;

  };

}
