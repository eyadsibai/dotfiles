{ pkgs, ... }: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the i3 window manager.
  services.xserver.windowManager.i3.enable = true;

  # Optional: i3status bar and dmenu launcher
  services.xserver.windowManager.i3.extraPackages = with pkgs; [
    i3status
    dmenu
  ];

  # Optional: Basic terminal
  environment.systemPackages = with pkgs; [
    st # Simple Terminal
  ];
}
