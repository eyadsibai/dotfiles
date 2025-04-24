{ pkgs, ... }: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the bspwm window manager.
  services.xserver.windowManager.bspwm.enable = true;

  # Optional: sxhkd for keybindings (highly recommended for bspwm)
  programs.sxhkd.enable = true;

  # Optional: Basic terminal and application launcher
  environment.systemPackages = with pkgs; [
    st # Simple Terminal
    dmenu # Dynamic menu
  ];
}
