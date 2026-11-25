# Key-only SSH, reachable on the LAN and Tailscale; authorized keys are in ./authorized-keys,
# which the Arch hosts install too (modules/home/arch.nix)
{
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = false;
    };
  };

  services.tailscale.enable = true;
}
