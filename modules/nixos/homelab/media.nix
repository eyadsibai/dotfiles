# Media: Plex, plus the apps that find, fetch, name and subtitle what it plays.
#   Jellyfin   the same library without Plex: no account or licence needed to watch
#              away from home, and it keeps working if Plex's servers don't
#   Navidrome  the music library for Subsonic apps on the phones (Symfonium, Amperfy)
#   Seerr      someone asks for a film or show
#   Sonarr     TV, Radarr films, Lidarr music: find releases, hand them to the
#              download clients (downloads.nix), file the results in /data/media
#   Prowlarr   the indexers, set up once and synced to all of the above
#   Bazarr     subtitles; Recyclarr keeps the TRaSH Guides quality sizes in sync
#   Pinchflat  YouTube channels downloaded into a Plex library
#   Tautulli   who watched what on Plex
#
# The first visit to each app asks for a login. Connecting them to each other
# (Prowlarr to Sonarr/Radarr/Lidarr, all of them to the download clients at
# 192.168.15.1:8090 and 127.0.0.1:8085) is a one-time step in their UIs, in
# docs/homelab.md.
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
  inherit (homelab) on shareMedia;

  # For the wiring below: the apps Prowlarr feeds, their API version, and the
  # SABnzbd category each files its downloads under (the folder names in /data/usenet)
  arrs = [
    "sonarr"
    "radarr"
    "lidarr"
  ];
  wired = arrs ++ [
    "prowlarr"
    "sabnzbd"
  ];
  apiVersion = {
    sonarr = "v3";
    radarr = "v3";
    lidarr = "v1";
  };
  category = {
    sonarr = "tvCategory";
    radarr = "movieCategory";
    lidarr = "musicCategory";
  };
  categoryName = {
    sonarr = "tv";
    radarr = "movies";
    lidarr = "music";
  };

  # With secrets, Sonarr, Radarr, Lidarr and Prowlarr take their API keys from sops
  # instead of making one up, so Recyclarr and the wiring below know them in advance.
  # Each key: any 32 hex characters, `openssl rand -hex 16`.
  apiKeyEnv = app: var: {
    sops.secrets."${app}/api-key" = { };
    sops.templates."${app}.env".content = "${var}=${config.sops.placeholder."${app}/api-key"}";
  };
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        my.homelab.apps = {
          plex = {
            port = 32400;
            title = "Plex";
            description = "Films, TV, music and YouTube";
            group = "Media";
            path = "/web";
            health = "/identity";
          };
          jellyfin = {
            port = 8096;
            title = "Jellyfin";
            description = "Films and TV, without Plex";
            group = "Media";
            health = "/health";
          };
          navidrome = {
            port = 4533;
            title = "Navidrome";
            description = "Music for the phones";
            group = "Media";
            health = "/ping";
          };
          seerr = {
            port = 5055;
            title = "Seerr";
            description = "Ask for a film or show";
            icon = "jellyseerr.svg";
            group = "Requests";
            health = "/api/v1/status";
          };
          sonarr = {
            port = 8989;
            title = "Sonarr";
            description = "TV";
            group = "Media";
            health = "/ping";
          };
          radarr = {
            port = 7878;
            title = "Radarr";
            description = "Films";
            group = "Media";
            health = "/ping";
          };
          lidarr = {
            port = 8686;
            title = "Lidarr";
            description = "Music";
            group = "Media";
            health = "/ping";
          };
          prowlarr = {
            port = 9696;
            title = "Prowlarr";
            description = "Indexers";
            group = "Downloads";
            health = "/ping";
          };
          bazarr = {
            port = 6767;
            title = "Bazarr";
            description = "Subtitles";
            group = "Media";
          };
          pinchflat = {
            port = 8945;
            title = "Pinchflat";
            description = "YouTube channels into Plex";
            group = "Media";
            health = "/healthcheck";
          };
          tautulli = {
            port = 8181;
            title = "Tautulli";
            description = "Plex statistics";
            group = "Media";
            health = "/status";
          };
          # Gets past Cloudflare's checks for Prowlarr's indexers; no UI of its own
          flaresolverr = {
            port = 8191;
            title = "FlareSolverr";
            group = "Downloads";
            dashboard = false;
          };
        };
      }

      (lib.mkIf (on "plex") {
        # Hardware transcoding on the GPU (hosts/home-server) needs a Plex Pass
        services.plex = {
          enable = true;
          openFirewall = true;
        };
        systemd.services.plex.serviceConfig = shareMedia;
      })

      (lib.mkIf (on "jellyfin") {
        # Libraries are added in its UI, from /data/media. It transcodes on the
        # NVIDIA GPU, as Plex does; NVENC needs the driver's other device nodes too.
        services.jellyfin = {
          enable = true;
          hardwareAcceleration = lib.mkIf config.hardware.nvidia.enabled {
            enable = true;
            type = "nvenc";
            device = "/dev/nvidia0";
          };
        };
        systemd.services.jellyfin.serviceConfig = shareMedia // {
          DeviceAllow = lib.mkIf config.hardware.nvidia.enabled [
            "/dev/nvidiactl rw"
            "/dev/nvidia-uvm rw"
            "/dev/nvidia-uvm-tools rw"
          ];
        };
        # TVs and phones at home find it by broadcast
        networking.firewall.allowedUDPPorts = [ 7359 ];
      })

      (lib.mkIf (on "navidrome") {
        # Reads the music Lidarr files; its own accounts, since the phone apps log
        # in with a username and password (the Subsonic API), not a passkey
        services.navidrome = {
          enable = true;
          settings = {
            Address = "0.0.0.0";
            Port = apps.navidrome.port;
            MusicFolder = "/data/media/music";
            BaseUrl = "";
          };
        };
        systemd.services.navidrome.serviceConfig.SupplementaryGroups = [ "media" ];
      })

      (lib.mkIf (on "seerr") {
        services.seerr = {
          enable = true;
          port = apps.seerr.port;
        };
      })

      (lib.mkIf (on "sonarr") (
        lib.mkMerge [
          {
            services.sonarr = {
              enable = true;
              settings.server.port = apps.sonarr.port;
              environmentFiles = lib.optional cfg.secrets.enable config.sops.templates."sonarr.env".path;
            };
            systemd.services.sonarr.serviceConfig = shareMedia;
          }
          (lib.mkIf cfg.secrets.enable (apiKeyEnv "sonarr" "SONARR__AUTH__APIKEY"))
        ]
      ))

      (lib.mkIf (on "radarr") (
        lib.mkMerge [
          {
            services.radarr = {
              enable = true;
              settings.server.port = apps.radarr.port;
              environmentFiles = lib.optional cfg.secrets.enable config.sops.templates."radarr.env".path;
            };
            systemd.services.radarr.serviceConfig = shareMedia;
          }
          (lib.mkIf cfg.secrets.enable (apiKeyEnv "radarr" "RADARR__AUTH__APIKEY"))
        ]
      ))

      (lib.mkIf (on "lidarr") (
        lib.mkMerge [
          {
            services.lidarr = {
              enable = true;
              settings.server.port = apps.lidarr.port;
              environmentFiles = lib.optional cfg.secrets.enable config.sops.templates."lidarr.env".path;
            };
            systemd.services.lidarr.serviceConfig = shareMedia;
          }
          (lib.mkIf cfg.secrets.enable (apiKeyEnv "lidarr" "LIDARR__AUTH__APIKEY"))
        ]
      ))

      (lib.mkIf (on "prowlarr") (
        lib.mkMerge [
          {
            services.prowlarr = {
              enable = true;
              settings.server.port = apps.prowlarr.port;
              environmentFiles = lib.optional cfg.secrets.enable config.sops.templates."prowlarr.env".path;
            };
          }
          (lib.mkIf cfg.secrets.enable (apiKeyEnv "prowlarr" "PROWLARR__AUTH__APIKEY"))
        ]
      ))

      # The apps connected to each other, which otherwise is a round of copying API
      # keys between their UIs after every reinstall: Prowlarr hands its indexers to
      # Sonarr, Radarr and Lidarr, and those three send downloads to SABnzbd. Each
      # connection is added if one of that name isn't there yet, so changes made in
      # the UIs afterwards stay. qBittorrent is still added by hand: its password is
      # set in its own UI.
      (lib.mkIf (cfg.secrets.enable && on "prowlarr") {
        systemd.services.arr-wiring = {
          description = "Connect Prowlarr, the *arr apps and SABnzbd";
          wantedBy = [ "multi-user.target" ];
          after = map (a: "${a}.service") (lib.filter on wired);
          wants = map (a: "${a}.service") (lib.filter on wired);
          onFailure = [ "notify-failure@%n.service" ];
          path = [
            pkgs.curl
            pkgs.jq
          ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            key() { tr -d '\n' < "/run/secrets/$1/api-key"; }

            # api <app> <port> <version> <method> <path> [body]
            api() {
              curl -fsS --retry 30 --retry-delay 4 --retry-all-errors \
                -H "X-Api-Key: $(key "$1")" -H 'Content-Type: application/json' \
                -X "$4" "http://127.0.0.1:$2/api/$3/$5" ''${6:+--data-binary "$6"}
            }

            # ensure <app> <port> <version> <endpoint> <name> <implementation> <field values as JSON>
            # Fills the app's own template for that implementation, so only the
            # fields that matter are named here
            ensure() {
              if api "$1" "$2" "$3" GET "$4" | jq -e --arg n "$5" 'any(.[]; .name == $n)' > /dev/null; then
                echo "$1: $5 is already there"
                return
              fi
              body=$(api "$1" "$2" "$3" GET "$4/schema" | jq --arg n "$5" --arg impl "$6" --argjson set "$7" '
                first(.[] | select(.implementation == $impl))
                | .name = $n | .enable = true
                | .fields |= map(if $set[.name] != null then .value = $set[.name] else . end)')
              api "$1" "$2" "$3" POST "$4" "$body" > /dev/null
              echo "$1: added $5"
            }

            ${lib.concatMapStrings (
              a:
              lib.optionalString (on a) ''
                ensure prowlarr ${toString apps.prowlarr.port} v1 applications ${apps.${a}.title} ${apps.${a}.title} \
                  "$(jq -n --arg k "$(key ${a})" '{prowlarrUrl: "http://127.0.0.1:${toString apps.prowlarr.port}", baseUrl: "http://127.0.0.1:${toString apps.${a}.port}", apiKey: $k}')"
              ''
              + lib.optionalString (on a && on "sabnzbd") ''
                ensure ${a} ${toString apps.${a}.port} ${apiVersion.${a}} downloadclient SABnzbd Sabnzbd \
                  "$(jq -n --arg k "$(key sabnzbd)" '{host: "127.0.0.1", port: ${toString apps.sabnzbd.port}, apiKey: $k, ${category.${a}}: "${categoryName.${a}}"}')"
              ''
            ) arrs}
          '';
        };
      })

      (lib.mkIf (on "bazarr") {
        services.bazarr = {
          enable = true;
          settings.general.port = apps.bazarr.port;
        };
        systemd.services.bazarr.serviceConfig = shareMedia;
      })

      (lib.mkIf (on "flaresolverr") {
        services.flaresolverr = {
          enable = true;
          port = apps.flaresolverr.port;
        };
      })

      (lib.mkIf (on "tautulli") {
        services.tautulli = {
          enable = true;
          port = apps.tautulli.port;
        };
      })

      (lib.mkIf (on "pinchflat") {
        # SECRET_KEY_BASE=<`openssl rand -hex 64`>. Until secrets exist it runs with
        # a built-in weak one, which only matters if it were reachable from outside.
        sops.secrets."pinchflat/env" = lib.mkIf cfg.secrets.enable { };
        services.pinchflat = {
          enable = true;
          # The maintained fork: nixpkgs marks the original insecure (outdated
          # dependencies, upstream stalled)
          package = pkgs.pinchflat-ngx;
          port = apps.pinchflat.port;
          mediaDir = "/data/media/youtube";
          selfhosted = !cfg.secrets.enable;
          secretsFile = lib.mkIf cfg.secrets.enable config.sops.secrets."pinchflat/env".path;
        };
        systemd.services.pinchflat.serviceConfig = shareMedia;
      })

      # The TRaSH Guides' file sizes for each quality, and one of their quality
      # profiles each (with the custom formats that score releases), kept in sync
      # daily. Sonarr: WEB-1080p; Radarr: HD Bluray + WEB. Others are listed in
      # github.com/TRaSH-Guides/Guides/tree/master/docs/json/<app>/quality-profiles
      # (the trash_id inside each file). Pick these profiles for new series and films.
      (lib.mkIf (cfg.secrets.enable && on "sonarr" && on "radarr") {
        services.recyclarr = {
          enable = true;
          configuration = {
            sonarr.series = {
              base_url = "http://127.0.0.1:${toString apps.sonarr.port}";
              api_key._secret = config.sops.secrets."sonarr/api-key".path;
              quality_definition.type = "series";
              quality_profiles = [ { trash_id = "72dae194fc92bf828f32cde7744e51a1"; } ];
            };
            radarr.movies = {
              base_url = "http://127.0.0.1:${toString apps.radarr.port}";
              api_key._secret = config.sops.secrets."radarr/api-key".path;
              quality_definition.type = "movie";
              quality_profiles = [ { trash_id = "d1d67249d3890e49bc12e275d989a7e9"; } ];
            };
          };
        };
      })
    ]
  );
}
