{
  # Key-only SSH, reachable on the LAN and Tailscale; authorized keys are in ./authorized-keys
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
      X11Forwarding = true;
    };
  };

  # RDP uses password login, so it is only reachable over Tailscale
  services.xrdp.enable = true;
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [ 3389 ];

  services.tailscale.enable = true;
}
