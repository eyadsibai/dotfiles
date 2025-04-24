{ pkgs, ... }: {
  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the awesome window manager.
  services.xserver.windowManager.awesome.enable = true;

  # Optional: Basic terminal
  environment.systemPackages = with pkgs; [
    st # Simple Terminal
  ];
}
