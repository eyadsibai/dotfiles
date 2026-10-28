# Desktop streaming to Moonlight (the Macs), over Tailscale only.
# Pair Moonlight and set the web UI password at https://localhost:47990
{ username, ... }:
{
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
