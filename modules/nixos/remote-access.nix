# Remote access: SSH everywhere, desktop streaming over Tailscale only.
# - Sunshine + Moonlight (from the Macs): NVENC-encoded desktop stream
# - gliff (from Hyprland machines): installed by nixarchy, runs over SSH
{ username, ... }:
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

  services.tailscale.enable = true;

  # Pair Moonlight and set the web UI password at https://localhost:47990
  services.sunshine = {
    enable = true;
    autoStart = true;
    capSysAdmin = true; # KMS capture, needed on NVIDIA
    openFirewall = false; # ports below, on Tailscale only
  };
  networking.firewall.interfaces.tailscale0 = {
    allowedTCPPorts = [
      47984
      47989
      47990
      48010
    ];
    allowedUDPPortRanges = [
      {
        from = 47998;
        to = 48000;
      }
    ];
  };

  users.users.${username}.extraGroups = [ "input" ]; # Sunshine's virtual keyboard/mouse
}
