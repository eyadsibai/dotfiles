# One passkey sign-in in front of the admin pages (the *arr apps, the download
# clients, AdGuard, Gatus, Homepage): tinyauth, at https://auth.<domain>, signs in
# through Pocket ID and leaves a cookie for the whole domain, and Caddy asks it about
# each request to an app with `auth = true` in the registry (default.nix).
#
# The apps keep their own logins as well: with the domain set their ports are
# closed, so Caddy is the only way in, but a second lock costs one sign-in per app.
#
# Needs the domain (passkeys need HTTPS) and, once: in Pocket ID, add an OIDC client
# "tinyauth" with callback https://auth.<domain>/api/oauth/callback/pocketid, and put
# its secret in secrets/home-server.yaml as tinyauth/client-secret and its id as
# tinyauth/env (`TINYAUTH_OAUTH_PROVIDERS_POCKETID_CLIENTID=<id>`), then
# `my.homelab.apps.auth.enable = true`. Off until then: Pocket ID has to be running
# before the client can be made.
{
  config,
  lib,
  homelab,
  ...
}:
let
  cfg = config.my.homelab;
  apps = cfg.apps;
  inherit (homelab) on;
  id = apps.id.url;
in
{
  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        my.homelab.apps = {
          auth = {
            enable = lib.mkDefault false;
            port = 3010;
            title = "Sign-in";
            group = "System";
            icon = "tinyauth.svg";
            health = "/api/healthz";
            dashboard = false;
          };
          # The admin pages behind it
          sonarr.auth = true;
          radarr.auth = true;
          lidarr.auth = true;
          prowlarr.auth = true;
          bazarr.auth = true;
          tautulli.auth = true;
          pinchflat.auth = true;
          flaresolverr.auth = true;
          qbittorrent.auth = true;
          sabnzbd.auth = true;
          adguard.auth = true;
          gatus.auth = true;
          scrutiny.auth = true;
          beszel.auth = true;
          homepage.auth = true;
        };
      }

      (lib.mkIf (on "auth") {
        assertions = [
          {
            assertion = cfg.domain != null && on "id";
            message = "The sign-in (my.homelab.apps.auth) needs the domain and Pocket ID.";
          }
        ];

        sops.secrets."tinyauth/env" = { };
        sops.secrets."tinyauth/client-secret".owner = config.services.tinyauth.user;

        services.tinyauth = {
          enable = true;
          environmentFile = config.sops.secrets."tinyauth/env".path;
          settings = {
            SERVER_ADDRESS = "127.0.0.1";
            SERVER_PORT = apps.auth.port;
            APPURL = apps.auth.url;
            AUTH_SECURECOOKIE = true;
            AUTH_TRUSTEDPROXIES = "127.0.0.1";
            # Straight to Pocket ID, with no username and password form
            OAUTH_AUTOREDIRECT = "pocketid";
            OAUTH_PROVIDERS_POCKETID_NAME = "Pocket ID";
            OAUTH_PROVIDERS_POCKETID_CLIENTSECRETFILE = config.sops.secrets."tinyauth/client-secret".path;
            OAUTH_PROVIDERS_POCKETID_AUTHURL = "${id}/authorize";
            OAUTH_PROVIDERS_POCKETID_TOKENURL = "${id}/api/oidc/token";
            OAUTH_PROVIDERS_POCKETID_USERINFOURL = "${id}/api/oidc/userinfo";
            OAUTH_PROVIDERS_POCKETID_REDIRECTURL = "${apps.auth.url}/api/oauth/callback/pocketid";
            OAUTH_PROVIDERS_POCKETID_SCOPES = "openid email profile groups";
          };
        };
      })
    ]
  );
}
