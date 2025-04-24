{ pkgs, ... }: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the dwm window manager.
  # Note: dwm requires configuration via C headers and recompilation.
  # This basic module only enables it; further customization is needed.
  services.xserver.windowManager.dwm.enable = true;

  # Optional: Basic terminal and dmenu
  environment.systemPackages = with pkgs; [
    st # Simple Terminal
    dmenu # Dynamic menu
  ];
}
