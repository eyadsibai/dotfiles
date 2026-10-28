# Key-only SSH, reachable on the LAN and Tailscale; authorized keys are in ./authorized-keys
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };

  services.tailscale.enable = true;
}
