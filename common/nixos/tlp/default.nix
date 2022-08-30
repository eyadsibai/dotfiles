{ is-laptop, ... }:
{
  services.tlp = {
    enable = is-laptop;
    settings = {
      USB_AUTOSUSPEND = 0;
    };
  };
}
