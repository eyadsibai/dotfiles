{ config, pkgs, ... }: {

  networking = {
    hostName = "eyad-nixos";
    networkmanager = {
      enable = true;
      plugins = [ pkgs.networkmanager-openvpn ];
    };
    wireless.enable = false; # Enables wireless support via wpa_supplicant.
    useDHCP = false; # deprecated
    interfaces = {
      enp3s0f0.useDHCP = true;
      wlp1s0.useDHCP = true;
    };
    # wireless.networks."xyz" = {
    #   psk = "11111";
    # };
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];

  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

}
