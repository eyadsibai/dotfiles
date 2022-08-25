{ inputs
, lib
, config
, pkgs
, ...
}:
let
  homeConfig = config.home-manager.users.eyad;
in
{
  networking = {

    #TODO move to wpa https://nixos.org/manual/nixos/stable/index.html#sec-wireless
    hostName = "eyad-nixos";
    networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };
    wireless.enable = false;
    # Enables wireless support via wpa_supplicant.
    useDHCP = false;
    # deprecated
    interfaces = {
      enp3s0f0 = { useDHCP = true; wakeOnLan.enable = true; };
      wlp1s0 = { useDHCP = true; wakeOnLan.enable = true; };
    };
    # wireless.networks."xyz" = {
    #   psk = "11111";
    # };
    firewall =
      {
        enable = true;
        allowedTCPPortRanges = [
          (lib.optionals
            homeConfig.services.kdeconnect.enable
            {
              from = 1714;
              to = 1764;
            })
        ];
        allowedUDPPortRanges = [
          (lib.optionals
            homeConfig.services.kdeconnect.enable
            {
              from = 1714;
              to = 1764;
            })
        ];
      };




  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ] ++ lib.lists.range 1714 1764; # kdeconnect
  # networking.firewall.allowedUDPPorts = [ ] ++ lib.lists.range 1714 1764; # kdeconnect

  networking.networkmanager.profiles = {
    "home-wifi" = {
      connection = {
        id = "home-wifi";
        uuid = "948346c4-3bf2-45e1-bb5f-146506d823d2";
        type = "wifi";
        interface-name = "wlp1s0";
        permissions = "";
      };
      wifi = {
        mac-address-blacklist = "";
        mode = "infrastructure";
        ssid = "Home Wi-Fi";
      };
      wifi-security = {
        auth-alg = "open";
        key-mgmt = "wpa-psk";
        psk = "0506805111";
      };
      ipv4 = {
        dns-search = "";
        method = "auto";
      };
      ipv6 = {
        addr-gen-mode = "stable-privacy";
        dns-search = "";
        method = "auto";
      };
    };
  };
}
