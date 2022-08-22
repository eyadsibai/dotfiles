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
  services.spacebar = {
    enable = true;
    package = pkgs.spacebar;
    config = {
      position = "top";
      display = "main";
      height = 26;
      title = "on";
      spaces = "on";
      clock = "on";
      power = "on";
      padding_left = 20;
      padding_right = 20;
      spacing_left = 25;
      spacing_right = 15;
      text_font = ''"Menlo:Regular:12.0"'';
      icon_font = ''"Font Awesome 5 Free:Solid:12.0"'';
      background_color = "0xff202020";
      foreground_color = "0xffa8a8a8";
      power_icon_color = "0xffcd950c";
      battery_icon_color = "0xffd75f5f";
      dnd_icon_color = "0xffa8a8a8";
      clock_icon_color = "0xffa8a8a8";
      power_icon_strip = " ";
      space_icon = "•";
      space_icon_strip = "1 2 3 4 5 6 7 8 9 10";
      spaces_for_all_displays = "on";
      display_separator = "on";
      display_separator_icon = "";
      space_icon_color = "0xff458588";
      space_icon_color_secondary = "0xff78c4d4";
      space_icon_color_tertiary = "0xfffff9b0";
      clock_icon = "";
      dnd_icon = "";
      clock_format = ''"%d/%m/%y %R"'';
      right_shell = "on";
      right_shell_icon = "";
      right_shell_command = "whoami";
    };
  };
  services.spotifyd.enable = true;


  users.users.eyad = {
    shell = pkgs.zsh;
  };
}
