# The download clients Sonarr, Radarr and Lidarr hand releases to.
#
# qBittorrent runs in a network namespace whose only route out is a WireGuard tunnel
# to the VPN provider (VPN-Confinement). If the tunnel is down it can't reach the
# internet at all, so torrents never go out from the home address. It stays off
# until the VPN is set up (my.homelab.vpn). From the host and the other apps it's at
# 192.168.15.1:8090; from the LAN and tailnet at home-server:8090.
#
# SABnzbd (Usenet) needs no VPN: it only talks to the Usenet provider, over TLS.
{ config, lib, ... }:
let
  cfg = config.my.homelab;
  apps = cfg.apps;
  on = name: cfg.enable && apps.${name}.enable;
  vpn = cfg.vpn;
  hostName = config.networking.hostName;
  shareMedia = {
    SupplementaryGroups = [ "media" ];
    UMask = lib.mkForce "0002";
  };
in
{
  options.my.homelab.vpn = {
    enable = lib.mkEnableOption ''
      the VPN namespace for qBittorrent (needs my.homelab.secrets.enable, with the
      provider's WireGuard config as vpn/wireguard.conf)
    '';
    forwardedPort = lib.mkOption {
      type = lib.types.nullOr lib.types.port;
      default = null;
      description = ''
        The port the VPN provider forwards to you, if it does (Proton, AirVPN).
        Without one, downloads work but fewer peers can connect.
      '';
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        my.homelab.apps = {
          qbittorrent = {
            enable = lib.mkDefault vpn.enable;
            port = 8090;
            title = "qBittorrent";
            description = "Torrents, through the VPN";
            group = "Downloads";
            # The namespace's address (VPN-Confinement's default)
            upstream = "192.168.15.1:8090";
          };
          sabnzbd = {
            port = 8085;
            title = "SABnzbd";
            description = "Usenet";
            group = "Downloads";
          };
        };

        assertions = [
          {
            assertion = !(on "qbittorrent") || vpn.enable;
            message = "qBittorrent only runs inside the VPN: set my.homelab.vpn.enable.";
          }
          {
            assertion = !vpn.enable || cfg.secrets.enable;
            message = "my.homelab.vpn needs my.homelab.secrets.enable for the WireGuard config.";
          }
        ];
      }

      (lib.mkIf vpn.enable {
        # The provider's WireGuard config file, as it gives it ([Interface] and [Peer])
        sops.secrets."vpn/wireguard.conf" = { };
        vpnNamespaces.wg = {
          enable = true;
          wireguardConfigFile = config.sops.secrets."vpn/wireguard.conf".path;
          accessibleFrom = cfg.lanSubnets ++ [ "100.64.0.0/10" ];
          portMappings = [
            {
              from = apps.qbittorrent.port;
              to = apps.qbittorrent.port;
            }
          ];
          openVPNPorts = lib.optional (vpn.forwardedPort != null) {
            port = vpn.forwardedPort;
            protocol = "both";
          };
        };
      })

      (lib.mkIf (on "qbittorrent") {
        # Settings are made in its web UI and kept (the first login's temporary
        # password is in `journalctl -u qbittorrent`)
        services.qbittorrent = {
          enable = true;
          webuiPort = apps.qbittorrent.port;
          torrentingPort = vpn.forwardedPort;
          extraArgs = [ "--confirm-legal-notice" ];
        };
        systemd.services.qbittorrent = {
          vpnConfinement = {
            enable = true;
            vpnNamespace = "wg";
          };
          serviceConfig = shareMedia;
        };
      })

      (lib.mkIf (on "sabnzbd") {
        # SABnzbd/secrets.ini, with [servers] entries for the Usenet provider; until
        # then servers are added in the UI (the config stays writable for that)
        sops.secrets."sabnzbd/secrets.ini" = lib.mkIf cfg.secrets.enable {
          owner = config.services.sabnzbd.user;
        };
        services.sabnzbd = {
          enable = true;
          configFile = null;
          allowConfigWrite = true;
          secretFiles = lib.optional cfg.secrets.enable config.sops.secrets."sabnzbd/secrets.ini".path;
          settings.misc = {
            host = "0.0.0.0";
            port = apps.sabnzbd.port;
            download_dir = "/data/usenet/incomplete";
            complete_dir = "/data/usenet/complete";
            permissions = "775";
            # Names it answers to (it refuses others, against DNS rebinding)
            host_whitelist = lib.concatStringsSep ", " (
              [ hostName ] ++ lib.optional (cfg.domain != null) "sabnzbd.${cfg.domain}"
            );
          };
        };
        systemd.services.sabnzbd.serviceConfig = shareMedia;
      })
    ]
  );
}
