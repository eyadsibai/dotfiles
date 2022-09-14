{ pkgs, ... }: {
  services.tlp = {
    enable = is-laptop && (
      !config.services.xserver.desktopManager.gnome.enable
    );
    settings = {
      USB_AUTOSUSPEND = 0;
    };
  };
}
