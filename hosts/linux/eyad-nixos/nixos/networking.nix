{ inputs
, lib
, config
, pkgs
, ...
}:
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
      enp3s0f0.useDHCP = true;
      wlp1s0.useDHCP = true;
    };
    # wireless.networks."xyz" = {
    #   psk = "11111";
    # };
  };
  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ] ++ lib.lists.range 1714 1764; # kdeconnect
  # networking.firewall.allowedUDPPorts = [ ] ++ lib.lists.range 1714 1764; # kdeconnect


  networking.firewall.enable = true;

  networking.firewall.allowedTCPPortRanges = [
    { from = 1714; to = 1764; }
  ];

  networking.firewall.allowedUDPPortRanges = [
    { from = 1714; to = 1764; }
  ];



  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";
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
