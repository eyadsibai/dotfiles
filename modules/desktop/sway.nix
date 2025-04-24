{ pkgs, ... }: {
  # Enable sway, a Wayland compositor (alternative to X11).
  programs.sway.enable = true;

  # Optional: Basic terminal, launcher, status bar
  environment.systemPackages = with pkgs; [
    foot # Wayland terminal
    wofi # Wayland launcher
    waybar # Wayland status bar
  ];

  # Ensure XWayland is enabled for compatibility with X11 apps
  programs.xwayland.enable = true;
}
