{ ... }:
{
  services.tlp = {
    enable = true;
    settings = {
      USB_AUTOSUSPEND = 0;
      RUNTIME_PM_BLACKLIST = "05:00.3 04:00.3 04:00.4";
    };
  };
}
