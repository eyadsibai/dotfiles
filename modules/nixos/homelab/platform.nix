# What every other service leans on: DNS (AdGuard Home), the dashboard (Homepage),
# uptime checks (Gatus), notifications (ntfy), disk health (Scrutiny, smartd), sign-on
# (Pocket ID) and hourly btrfs snapshots of the NVMe's state.
#
# Anything that fails says so on ntfy. A unit with
# `onFailure = [ "notify-failure@%n.service" ]` sends its last log lines to the
# `homelab` topic; subscribe to it in the ntfy phone app.
{
  config,
  lib,
  pkgs,
  homelab,
  ...
}:
let
  cfg = config.my.homelab;
  apps = cfg.apps;
  inherit (homelab) on;
  enabledApps = lib.filterAttrs (_: a: a.enable) apps;
  hostName = config.networking.hostName;
  ntfyLocal = "http://127.0.0.1:${toString apps.ntfy.port}";

  # Homepage groups, in this order; any other group follows them
  groupOrder = [
    "Media"
    "Requests"
    "Downloads"
    "Reading"
    "Photos & documents"
    "Home"
    "System"
  ];
  tiles = lib.attrValues (
    lib.mapAttrs (name: a: a // { inherit name; }) (lib.filterAttrs (_: a: a.dashboard) enabledApps)
  );
  byGroup = lib.groupBy (a: a.group) tiles;
  groups =
    lib.filter (g: byGroup ? ${g}) groupOrder
    ++ lib.filter (g: !lib.elem g groupOrder) (lib.attrNames byGroup);
in
{
  options.my.homelab.beszelKey = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "ssh-ed25519 AAAA...";
    description = ''
      The Beszel hub's public key, from its "Add system" dialog (host 127.0.0.1,
      port 45876). Not secret: it only lets the hub prove itself to the agent.
    '';
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        my.homelab.apps = {
          homepage = {
            port = 8082;
            title = "Homepage";
            group = "System";
            dashboard = false;
          };
          adguard = {
            port = 3002;
            title = "AdGuard Home";
            description = "DNS and ad blocking for the house";
            icon = "adguard-home.svg";
            group = "System";
          };
          gatus = {
            port = 8083;
            title = "Gatus";
            description = "Is everything up?";
            group = "System";
            health = "/health";
          };
          ntfy = {
            port = 2586;
            title = "ntfy";
            description = "Notifications (topic: homelab)";
            group = "System";
            health = "/v1/health";
          };
          scrutiny = {
            port = 8084;
            title = "Scrutiny";
            description = "Disk health";
            group = "System";
            health = "/api/health";
          };
          beszel = {
            port = 8092;
            title = "Beszel";
            description = "CPU, memory, disk and GPU over time";
            group = "System";
            health = "/api/health";
          };
          # Passkeys need HTTPS, so sign-on starts with the domain
          id = {
            enable = lib.mkDefault (cfg.domain != null);
            port = 1411;
            title = "Pocket ID";
            description = "Sign-on with passkeys";
            icon = "pocket-id.svg";
            group = "System";
            health = "/healthz";
          };
        };

        systemd.services."notify-failure@" = {
          description = "Tell ntfy that %i failed";
          path = [
            pkgs.curl
            config.systemd.package
          ];
          scriptArgs = "%i";
          serviceConfig.Type = "oneshot";
          script = ''
            journalctl -u "$1" -n 20 --no-pager -o cat |
              curl -fsS -H "Title: $1 failed on ${hostName}" -H "Priority: high" -H "Tags: warning" \
                --data-binary @- ${ntfyLocal}/homelab
          '';
        };
        # Both upgrade sources (GitHub and the CI's builds) run as nixos-upgrade
        systemd.services.nixos-upgrade = lib.mkIf config.my.autoUpgrade.enable {
          onFailure = [ "notify-failure@%n.service" ];
          # Rolling back NixOS doesn't roll back what new versions of the apps did
          # to their databases. A snapshot of the state first is what does: btrbk's
          # usual snapshots, taken now, under /mnt/btr-pool/snapshots.
          preStart = lib.mkAfter ''
            ${lib.getExe pkgs.btrbk} -c /etc/btrbk/local.conf snapshot
          '';
        };
      }

      (lib.mkIf (on "adguard") {
        services.adguardhome = {
          enable = true;
          # Settings and clients added in its web UI survive restarts. Lists set here
          # (the filters and rewrites below) don't: each start replaces them with
          # these, so further block lists go in this file, not the UI.
          mutableSettings = true;
          settings = {
            http.address = "0.0.0.0:${toString apps.adguard.port}";
            dns = {
              bind_hosts = [ "0.0.0.0" ];
              port = 53;
              upstream_dns = [
                "https://dns.quad9.net/dns-query"
                "https://cloudflare-dns.com/dns-query"
              ];
              bootstrap_dns = [
                "9.9.9.9"
                "1.1.1.1"
              ];
            };
            filters = [
              {
                enabled = true;
                id = 1;
                name = "AdGuard DNS filter";
                url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_1.txt";
              }
            ];
            # At home the apps' names point at the LAN address. Away, Cloudflare's
            # public record points them at the tailnet address (docs/homelab.md).
            filtering.rewrites = lib.optionals (cfg.domain != null && cfg.lanAddress != null) [
              {
                domain = cfg.domain;
                answer = cfg.lanAddress;
                enabled = true;
              }
              {
                domain = "*.${cfg.domain}";
                answer = cfg.lanAddress;
                enabled = true;
              }
            ];
          };
        };
        networking.firewall = {
          allowedTCPPorts = [ 53 ];
          allowedUDPPorts = [ 53 ];
        };
      })

      (lib.mkIf (on "homepage") {
        services.homepage-dashboard = {
          enable = true;
          listenPort = apps.homepage.port;
          allowedHosts = lib.concatStringsSep "," (
            [
              "${hostName}:${toString apps.homepage.port}"
              "localhost:${toString apps.homepage.port}"
              "127.0.0.1:${toString apps.homepage.port}"
            ]
            ++ lib.optionals (cfg.domain != null) [
              cfg.domain
              "homepage.${cfg.domain}"
            ]
          );
          settings = {
            title = hostName;
            headerStyle = "clean";
            statusStyle = "dot";
          };
          widgets = [
            {
              resources = {
                cpu = true;
                memory = true;
                disk = [
                  "/var/lib"
                  "/data"
                ];
              };
            }
            {
              search = {
                provider = "duckduckgo";
                target = "_blank";
              };
            }
          ];
          services = map (g: {
            ${g} = map (a: {
              ${a.title} = {
                href = a.url;
                inherit (a) description icon;
                siteMonitor = "http://${a.upstream}${a.health}";
              };
            }) byGroup.${g};
          }) groups;
        };
      })

      (lib.mkIf (on "gatus") {
        services.gatus = {
          enable = true;
          settings = {
            web.port = apps.gatus.port;
            storage = {
              type = "sqlite";
              path = "/var/lib/gatus/data.db";
            };
            alerting.ntfy = lib.mkIf (on "ntfy") {
              url = ntfyLocal;
              topic = "homelab";
              priority = 4;
              default-alert = {
                failure-threshold = 3;
                success-threshold = 2;
                send-on-resolved = true;
              };
            };
            endpoints =
              lib.mapAttrsToList (_: a: {
                name = a.title;
                group = a.group;
                url = "http://${a.upstream}${a.health}";
                interval = "2m";
                # Up is anything but a server error: many apps answer 401 or a redirect
                conditions = [ "[STATUS] < 500" ];
                alerts = lib.optional (on "ntfy") { type = "ntfy"; };
              }) (lib.filterAttrs (n: _: n != "gatus") enabledApps)
              # The checks above go straight to each app. These go the way people
              # do: through DNS, Caddy and the certificate, which can each break
              # while every app is fine.
              ++ lib.optionals (cfg.domain != null) [
                {
                  name = "HTTPS and certificate";
                  group = "System";
                  url = "https://${cfg.domain}";
                  interval = "10m";
                  conditions = [
                    "[STATUS] < 500"
                    # Renewal starts 30 days out; 10 left means it has been failing
                    "[CERTIFICATE_EXPIRATION] > 240h"
                  ];
                  alerts = lib.optional (on "ntfy") { type = "ntfy"; };
                }
              ]
              ++ lib.optionals (cfg.domain != null && cfg.lanAddress != null && on "adguard") [
                {
                  name = "DNS at home";
                  group = "System";
                  url = "127.0.0.1";
                  dns = {
                    query-name = "homepage.${cfg.domain}";
                    query-type = "A";
                  };
                  interval = "5m";
                  conditions = [ "[BODY] == ${cfg.lanAddress}" ];
                  alerts = lib.optional (on "ntfy") { type = "ntfy"; };
                }
              ];
          };
        };
      })

      (lib.mkIf (on "ntfy") {
        services.ntfy-sh = {
          enable = true;
          settings = {
            base-url = apps.ntfy.url;
            listen-http = ":${toString apps.ntfy.port}";
            behind-proxy = cfg.domain != null;
            # iPhones only get instant notifications relayed through ntfy.sh
            upstream-base-url = "https://ntfy.sh";
          };
        };
      })

      (lib.mkIf (on "scrutiny") {
        services.scrutiny = {
          enable = true;
          collector.enable = true;
          settings = {
            web.listen.port = apps.scrutiny.port;
            notify.urls = lib.optional (on "ntfy") "ntfy://127.0.0.1:${toString apps.ntfy.port}/homelab?scheme=http";
          };
        };
        # Short self-tests nightly and a long one on Saturdays; Scrutiny shows the
        # results. A disk that has spun down is skipped rather than woken just to be
        # asked how it is (`-n standby`), until the self-test wakes it anyway.
        services.smartd = {
          enable = true;
          defaults.autodetected = "-a -o on -S on -s (S/../.././02|L/../../6/03) -n standby,q";
        };
      })

      # Every alert above goes through ntfy on this machine, so if the machine itself
      # dies, hangs or loses its connection, nothing says so. It checks in with an
      # outside service every 5 minutes instead, which notifies when it stops:
      # healthchecks.io (free), a check with a 5 minute period, its ping URL as
      # heartbeat-url in secrets/home-server.yaml, and its alerts sent to the phone.
      {
        # One btrfs holds the store, every service's state, the snapshots, images
        # and the games. Full, everything fails at once; so ntfy hears at 90%.
        systemd.services.disk-space = lib.mkIf (on "ntfy") {
          description = "Tell ntfy when a filesystem is nearly full";
          path = [
            pkgs.coreutils
            pkgs.gawk
            pkgs.curl
          ];
          serviceConfig.Type = "oneshot";
          script = ''
            df --output=pcent,target -x tmpfs -x devtmpfs -x efivarfs -x vfat -x fuse.mergerfs |
              awk 'NR > 1 && $1 + 0 >= 90 { print $2 " is " $1 " full" }' |
              while read -r line; do
                curl -fsS -H "Title: Disk nearly full on ${hostName}" -H "Tags: warning" \
                  --data-binary "$line" ${ntfyLocal}/homelab
              done
          '';
          startAt = "hourly";
        };

        # Reads every block back against its checksum, so a failing NVMe shows up
        # while the backups still hold a good copy
        services.btrfs.autoScrub = {
          enable = true;
          fileSystems = [ "/mnt/btr-pool" ];
          interval = "monthly";
        };
        systemd.services."btrfs-scrub@".onFailure = [ "notify-failure@%n.service" ];

        # The server resolves names through public DNS, not through its own AdGuard
        # (which the router hands out): if AdGuard were down, the upgrade, the
        # certificate, the backups and ntfy would all fail with it
        networking.nameservers = [
          "9.9.9.9"
          "1.1.1.1"
        ];
        networking.networkmanager.dns = "none";
      }

      (lib.mkIf cfg.heartbeat {
        sops.secrets.heartbeat-url = { };
        systemd.services.heartbeat = {
          description = "Tell healthchecks.io the server is up";
          path = [ pkgs.curl ];
          serviceConfig.Type = "oneshot";
          script = ''
            curl -fsS -m 10 --retry 3 "$(<${config.sops.secrets.heartbeat-url.path})" > /dev/null
          '';
          startAt = "*:0/5";
        };
      })

      # Beszel keeps a history of how busy the machine has been, which Gatus (up or
      # down) and Scrutiny (disk health) don't. The hub is the web UI; the agent on
      # the same machine reports to it once it knows the hub's public key
      # (my.homelab.beszelKey).
      (lib.mkIf (on "beszel") (
        lib.mkMerge [
          {
            services.beszel.hub = {
              enable = true;
              host = "0.0.0.0";
              port = apps.beszel.port;
            };
          }
          (lib.mkIf (cfg.beszelKey != null) {
            services.beszel.agent = {
              enable = true;
              environment = {
                LISTEN = "127.0.0.1:45876";
                KEY = cfg.beszelKey;
              };
              # The disks' SMART data, as Scrutiny reads it
              smartmon.enable = true;
            };
          })
        ]
      ))

      (lib.mkIf (on "id") {
        # ENCRYPTION_KEY: `openssl rand -base64 32`
        sops.secrets."pocket-id/encryption-key".owner = config.services.pocket-id.user;
        services.pocket-id = {
          enable = true;
          settings = {
            APP_URL = apps.id.url;
            TRUST_PROXY = true;
            ANALYTICS_DISABLED = true;
          };
          credentials.ENCRYPTION_KEY = config.sops.secrets."pocket-id/encryption-key".path;
        };
      })

      # Hourly snapshots of the state subvolumes, kept 2 days, then daily for 2 weeks
      # and weekly for 6. The top level is mounted at /mnt/btr-pool for btrbk to see them.
      {
        fileSystems."/mnt/btr-pool" = {
          device = "/dev/mapper/crypted";
          fsType = "btrfs";
          options = [
            "subvol=/"
            "noatime"
          ];
        };
        systemd.tmpfiles.settings.btrbk."/mnt/btr-pool/snapshots".d = {
          mode = "0700";
        };
        systemd.services.btrbk-local.onFailure = [ "notify-failure@%n.service" ];
        services.btrbk.instances.local = {
          onCalendar = "hourly";
          settings = {
            snapshot_preserve_min = "2d";
            snapshot_preserve = "14d 6w";
            volume."/mnt/btr-pool" = {
              snapshot_dir = "snapshots";
              subvolume = {
                var-lib = { };
                home = { };
                persist = { };
              };
            };
          };
        };
      }
    ]
  );
}
