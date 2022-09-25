{ inputs
, lib
, config
, pkgs
, hostname
, username
, ...
}:
let
  homeConfig = config.home-manager.users.${username};
  defaultNetworkProfile =
    { ssid
    , psk
    , uuid
    , nic ? "wlp1s0"
    , auth-alg ? "open"
    , key-mgmt ? "wps-psk"
    , permissions ? ""
    }: {
      connection = {
        id = ssid;
        uuid = uuid;
        type = "wifi";
        interface-name = nic;
        permissions = permissions;
      };
      wifi = {
        mac-address-blacklist = "";
        mode = "infrastructure";
        ssid = ssid;
      };
      wifi-security = {
        auth-alg = auth-alg;
        key-mgmt = key-mgmt;
        psk = psk;
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
in
{

  environment.systemPackages = [
    pkgs.wpa_supplicant_gui
  ];

  networking = {
    #TODO move to wpa https://nixos.org/manual/nixos/stable/index.html#sec-wireless
    hostName = hostname;
    # networkmanager = {
    #   enable = true;
    #   plugins = [ pkgs.networkmanager-openvpn ];
    # };
    wireless = {
      enable = true;
      # iwd.enable = true;
      networks = config.secrets.networks;
      userControlled.enable = true;
      # Configuration for wpa_gui
      extraConfig = ''
        ctrl_interface=/run/wpa_supplicant
        ctrl_interface_group=wheel
        # eapol_version=2
      '';
    };

    interfaces = {
      enp3s0f0 = {
        useDHCP = true;
        wakeOnLan.enable = true;
      };
      wlp1s0 = {
        useDHCP = true;
        wakeOnLan.enable = true;
      };

      # if I am at work
      # wlp4s0f3u3 = {
      #   useDHCP = true;
      #   ipv4.routes = [
      #     {
      #       address = "192.168.11.37";
      #       prefixLength = 16;
      #       via = "192.168.89.1";
      #       options.scope = "global";
      #     }
      #     {
      #       address = "192.168.3.116";
      #       prefixLength = 16;
      #       via = "192.168.89.1";
      #       options.scope = "global";
      #     }
      #     {
      #       address = "192.168.2.17";
      #       prefixLength = 16;
      #       via = "192.168.89.1";
      #       options.scope = "global";
      #     }
      #   ];
      # };

    };
    firewall = {
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
    # }

    # networking.networkmanager.profiles = {
    #   "emad-uncle" = defaultNetworkProfile
    #     {
    #       ssid = "Emad_5G";
    #       psk = ${config.secrets.networks."Emad_5G"};
    #       uuid = "820d32fe-c2a5-4eeb-8959-61be846ac223";
    #     };
    # };
  };
}
