# Media: Plex, plus the apps that find, fetch, name and subtitle what it plays.
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
  ...
}:
let
  cfg = config.my.homelab;
  apps = cfg.apps;
  on = name: cfg.enable && apps.${name}.enable;

  # The apps that write into /data share the `media` group and leave files
  # group-writable, so each can rename or hard-link what another wrote
  shareMedia = {
    SupplementaryGroups = [ "media" ];
    UMask = lib.mkForce "0002";
  };

  # With secrets, Sonarr and Radarr take their API keys from sops instead of
  # making one up, so Recyclarr (and anything later) knows them in advance.
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

      (lib.mkIf (on "lidarr") {
        services.lidarr = {
          enable = true;
          settings.server.port = apps.lidarr.port;
        };
        systemd.services.lidarr.serviceConfig = shareMedia;
      })

      (lib.mkIf (on "prowlarr") {
        services.prowlarr = {
          enable = true;
          settings.server.port = apps.prowlarr.port;
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

      # The TRaSH Guides' file sizes for each quality, kept in sync daily. Quality
      # profiles and custom formats can be added here later, or set in the UIs.
      (lib.mkIf (cfg.secrets.enable && on "sonarr" && on "radarr") {
        services.recyclarr = {
          enable = true;
          configuration = {
            sonarr.series = {
              base_url = "http://127.0.0.1:${toString apps.sonarr.port}";
              api_key._secret = config.sops.secrets."sonarr/api-key".path;
              quality_definition.type = "series";
            };
            radarr.movies = {
              base_url = "http://127.0.0.1:${toString apps.radarr.port}";
              api_key._secret = config.sops.secrets."radarr/api-key".path;
              quality_definition.type = "movie";
            };
          };
        };
      })
    ]
  );
}
