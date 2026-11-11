# Everything that isn't media or plumbing:
#   Miniflux        RSS and YouTube feeds, read in its UI or by newsboat on any machine
#   Karakeep        read-later and bookmarks, with full-page archives
#   Paperless-ngx   scanned letters and PDFs, OCR'd and searchable
#   Immich          photos and videos from the phones, in /data/photos
#   Audiobookshelf  audiobooks and podcasts, with phone apps
{
  config,
  lib,
  homelab,
  ...
}:
let
  cfg = config.my.homelab;
  apps = cfg.apps;
  inherit (homelab) on shareMedia;

  # Signing in through Pocket ID needs it running at its https address
  oidcNeeds = name: {
    assertion = cfg.secrets.enable && cfg.domain != null && on "id";
    message = "my.homelab.apps.${name}.oidc needs the secrets, the domain and Pocket ID.";
  };
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        my.homelab.apps = {
          miniflux = {
            port = 8070;
            title = "Miniflux";
            description = "Feeds";
            group = "Reading";
            health = "/healthcheck";
          };
          karakeep = {
            port = 3000;
            title = "Karakeep";
            description = "Read later and bookmarks";
            group = "Reading";
            health = "/api/health";
          };
          audiobookshelf = {
            port = 8000;
            title = "Audiobookshelf";
            description = "Audiobooks and podcasts";
            group = "Reading";
            health = "/healthcheck";
          };
          immich = {
            port = 2283;
            title = "Immich";
            description = "Photos";
            group = "Photos & documents";
            health = "/api/server/ping";
          };
          paperless = {
            port = 28981;
            title = "Paperless";
            description = "Documents";
            icon = "paperless-ngx.svg";
            group = "Photos & documents";
          };
        };
      }

      (lib.mkIf (on "miniflux") {
        # ADMIN_USERNAME=... and ADMIN_PASSWORD=... lines. Until secrets exist, make
        # the first user by hand (docs/homelab.md).
        sops.secrets."miniflux/admin.env" = lib.mkIf cfg.secrets.enable { };
        services.miniflux = {
          enable = true;
          adminCredentialsFile = lib.mkIf cfg.secrets.enable config.sops.secrets."miniflux/admin.env".path;
          config = {
            LISTEN_ADDR = "0.0.0.0:${toString apps.miniflux.port}";
            BASE_URL = apps.miniflux.url;
            CREATE_ADMIN = cfg.secrets.enable;
            # ~500 YouTube channels: fetch more feeds per round, and show each
            # video's length
            POLLING_FREQUENCY = 30;
            BATCH_SIZE = 200;
            WORKER_POOL_SIZE = 10;
            FETCH_YOUTUBE_WATCH_TIME = 1;
          };
        };
      })

      # Pocket ID's client "miniflux", with callback
      # https://miniflux.<domain>/oauth2/oidc/callback
      (lib.mkIf (on "miniflux" && apps.miniflux.oidc) {
        assertions = [ (oidcNeeds "miniflux") ];
        sops.secrets."miniflux/oidc-client-id" = { };
        sops.secrets."miniflux/oidc-client-secret" = { };
        sops.templates."miniflux-oidc.env".content = ''
          OAUTH2_CLIENT_ID=${config.sops.placeholder."miniflux/oidc-client-id"}
          OAUTH2_CLIENT_SECRET=${config.sops.placeholder."miniflux/oidc-client-secret"}
        '';
        services.miniflux.config = {
          OAUTH2_PROVIDER = "oidc";
          OAUTH2_OIDC_PROVIDER_NAME = "Pocket ID";
          OAUTH2_OIDC_DISCOVERY_ENDPOINT = apps.id.url;
          OAUTH2_REDIRECT_URL = "${apps.miniflux.url}/oauth2/oidc/callback";
        };
        systemd.services.miniflux.serviceConfig.EnvironmentFile = [
          config.sops.templates."miniflux-oidc.env".path
        ];
      })

      (lib.mkIf (on "karakeep") {
        services.karakeep = {
          enable = true;
          extraEnvironment = {
            PORT = toString apps.karakeep.port;
            NEXTAUTH_URL = apps.karakeep.url;
            DISABLE_NEW_RELEASE_CHECK = "true";
          };
        };
      })

      # Pocket ID's client "paperless", with callback
      # https://paperless.<domain>/accounts/oidc/pocketid/login/callback/
      (lib.mkIf (on "paperless" && apps.paperless.oidc) {
        assertions = [ (oidcNeeds "paperless") ];
        sops.secrets."paperless/oidc-client-id" = { };
        sops.secrets."paperless/oidc-client-secret" = { };
        # Read by systemd and by a shell, so the JSON sits in single quotes
        sops.templates."paperless-oidc.env".content =
          "PAPERLESS_SOCIALACCOUNT_PROVIDERS='"
          + builtins.toJSON {
            openid_connect = {
              OAUTH_PKCE_ENABLED = true;
              APPS = [
                {
                  provider_id = "pocketid";
                  name = "Pocket ID";
                  client_id = config.sops.placeholder."paperless/oidc-client-id";
                  secret = config.sops.placeholder."paperless/oidc-client-secret";
                  settings.server_url = apps.id.url;
                }
              ];
            };
          }
          + "'\n";
        services.paperless = {
          environmentFile = config.sops.templates."paperless-oidc.env".path;
          settings.PAPERLESS_APPS = "allauth.socialaccount.providers.openid_connect";
        };
      })

      (lib.mkIf (on "audiobookshelf") {
        services.audiobookshelf = {
          enable = true;
          host = "0.0.0.0";
          port = apps.audiobookshelf.port;
        };
        systemd.services.audiobookshelf.serviceConfig = shareMedia;
      })

      (lib.mkIf (on "immich") {
        # On the big pool rather than the NVMe; backed up off-site (backup.nix).
        # Face and object recognition run on the CPU.
        services.immich = {
          enable = true;
          host = "0.0.0.0";
          port = apps.immich.port;
          mediaLocation = "/data/photos";
        };
        systemd.tmpfiles.settings.immich."/data/photos".d = {
          mode = "0750";
          user = config.services.immich.user;
          group = config.services.immich.group;
        };
      })

      (lib.mkIf (on "paperless") {
        # The admin's password; until secrets exist, `sudo paperless-manage createsuperuser`
        sops.secrets."paperless/admin-password" = lib.mkIf cfg.secrets.enable { };
        services.paperless = {
          enable = true;
          address = "0.0.0.0";
          port = apps.paperless.port;
          database.createLocally = true;
          passwordFile = lib.mkIf cfg.secrets.enable config.sops.secrets."paperless/admin-password".path;
          settings = {
            PAPERLESS_URL = apps.paperless.url;
            PAPERLESS_OCR_LANGUAGE = "eng+ara";
            PAPERLESS_CONSUMER_RECURSIVE = true;
            PAPERLESS_CONSUMER_SUBDIRS_AS_TAGS = true;
          };
        };
      })
    ]
  );
}
