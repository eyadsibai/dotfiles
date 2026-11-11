# The homelab on home-server (docs/homelab.md). Every web app registers itself in
# my.homelab.apps with its port, title and icon, and the rest follows from that entry:
# its address, its tile on Homepage, its Gatus uptime check and, once there's a
# domain, its Caddy site. `my.homelab.apps.<name>.enable = false` turns an app off.
#
# It works in two stages, so it can run before anything is decided:
#   - no domain: each app at http://home-server:<port>, its port open on the LAN and
#     tailnet (nothing is forwarded from the internet)
#   - my.homelab.domain set: https://<app>.<domain> through Caddy with one wildcard
#     certificate (Let's Encrypt over Cloudflare DNS), and only 80 and 443 open
# Whatever needs a secret waits for my.homelab.secrets.enable.
{
  config,
  lib,
  inputs,
  username,
  ...
}:
let
  cfg = config.my.homelab;
  inherit (lib) mkOption types;
  enabledApps = lib.filterAttrs (_: a: a.enable) cfg.apps;
  hostName = config.networking.hostName;

  # Caddy asks tinyauth (auth.nix) whether the visitor is signed in before passing
  # the request on; if not, they're sent to sign in with a passkey
  signIn =
    a:
    lib.optionalString (a.auth && cfg.apps.auth.enable) ''
      forward_auth ${cfg.apps.auth.upstream} {
        uri /api/auth/caddy
        copy_headers Remote-User Remote-Name Remote-Email Remote-Groups
      }
    '';
in
{
  imports = [
    inputs.vpn-confinement.nixosModules.default
    ./storage.nix
    ./platform.nix
    ./backup.nix
    ./media.nix
    ./downloads.nix
    ./apps.nix
    ./gaming.nix
    ./shares.nix
    ./auth.nix
  ];

  options.my.homelab = {
    enable = lib.mkEnableOption "the homelab services";

    domain = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "home.example.com";
      description = ''
        Base domain, on Cloudflare: each app is served at https://<app>.<domain> and
        Homepage at https://<domain>. Needs my.homelab.secrets.enable (the Cloudflare
        token) and acmeEmail. null serves each app on its own port instead.
      '';
    };

    acmeEmail = mkOption {
      type = types.str;
      description = "The Let's Encrypt account's address. Only read once a domain is set.";
    };

    lanAddress = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "192.168.1.10";
      description = ''
        home-server's fixed LAN address. With a domain, AdGuard Home answers
        *.<domain> with it, so devices at home reach the apps without Tailscale.
      '';
    };

    lanSubnets = mkOption {
      type = types.listOf types.str;
      default = [
        "192.168.0.0/16"
        "10.0.0.0/8"
        "172.16.0.0/12"
      ];
      description = "Networks treated as home, e.g. allowed into the VPN namespace's web UI.";
    };

    heartbeat = lib.mkOption {
      type = lib.types.bool;
      default = cfg.secrets.enable;
      defaultText = lib.literalExpression "config.my.homelab.secrets.enable";
      description = ''
        Ping an outside check (healthchecks.io) every 5 minutes, so the server going
        down is noticed (platform.nix). Needs heartbeat-url in the secrets.
      '';
    };

    secrets = {
      enable = lib.mkEnableOption ''
        secrets from secrets/home-server.yaml (sops), for the parts that need them:
        the certificate, the VPN, backups, Pocket ID, API keys. Create that file before
        turning this on (docs/homelab.md lists its keys)
      '';
      file = mkOption {
        type = types.path;
        default = ../../../secrets/home-server.yaml;
      };
    };

    apps = mkOption {
      default = { };
      description = "Web apps, each with an address, a dashboard tile and an uptime check.";
      type = types.attrsOf (
        types.submodule (
          { name, config, ... }:
          {
            options = {
              enable = mkOption {
                type = types.bool;
                default = true;
              };
              port = mkOption { type = types.port; };
              title = mkOption {
                type = types.str;
                default = name;
              };
              description = mkOption {
                type = types.str;
                default = "";
              };
              # A name from github.com/homarr-labs/dashboard-icons, as Homepage takes it
              icon = mkOption {
                type = types.str;
                default = "${name}.svg";
              };
              group = mkOption { type = types.str; };
              # Where Caddy and Gatus reach it; most apps listen on every interface
              upstream = mkOption {
                type = types.str;
                default = "127.0.0.1:${toString config.port}";
              };
              # A path that answers without logging in, for the uptime check
              health = mkOption {
                type = types.str;
                default = "/";
              };
              # Added to the address people open, e.g. Plex's /web
              path = mkOption {
                type = types.str;
                default = "";
              };
              dashboard = mkOption {
                type = types.bool;
                default = true;
              };
              # Behind the passkey sign-in (auth.nix) once there's a domain. For
              # admin pages with weak or no login of their own; not for apps that
              # phones or TVs talk to directly (Plex, Immich, Audiobookshelf, ntfy)
              auth = mkOption {
                type = types.bool;
                default = false;
              };
              # Signs in with a passkey through Pocket ID itself (OIDC), for apps that
              # support it (Miniflux, Paperless). Off until its client has been made
              # in Pocket ID and its id and secret are in the secrets
              # (docs/homelab.md, "Signing in")
              oidc = mkOption {
                type = types.bool;
                default = false;
              };
              url = mkOption {
                type = types.str;
                readOnly = true;
                description = "Where people open it: derived from the domain, or host and port.";
              };
            };
            config.url =
              (
                if cfg.domain != null then
                  "https://${name}.${cfg.domain}"
                else
                  "http://${hostName}:${toString config.port}"
              )
              + config.path;
          }
        )
      );
    };
  };

  config = lib.mkMerge [
    {
      # Shared by the homelab's modules, as their `homelab` argument
      _module.args.homelab = {
        # Whether an app is on (the homelab, and the app in it)
        on = name: cfg.enable && cfg.apps.${name}.enable;
        # For the apps that write into /data: they share the `media` group and leave
        # files group-writable, so each can rename or hard-link what another wrote
        shareMedia = {
          SupplementaryGroups = [ "media" ];
          UMask = lib.mkForce "0002";
        };
      };
    }

    (lib.mkIf cfg.enable (
      lib.mkMerge [
        {
          assertions = [
            {
              assertion = cfg.domain == null || cfg.secrets.enable;
              message = "my.homelab.domain needs my.homelab.secrets.enable: the certificate comes from a Cloudflare token in sops.";
            }
          ];

          sops.defaultSopsFile = lib.mkIf cfg.secrets.enable cfg.secrets.file;

          # I can read the libraries and downloads too, e.g. over SSH
          users.users.${username}.extraGroups = [ "media" ];
        }

        (lib.mkIf (cfg.domain == null) {
          networking.firewall.allowedTCPPorts = lib.mapAttrsToList (_: a: a.port) enabledApps;
        })

        (lib.mkIf (cfg.domain != null) {
          # CF_DNS_API_TOKEN=<token with Zone:DNS:Edit on the domain's zone>
          sops.secrets.cloudflare-acme = { };
          security.acme = {
            acceptTerms = true;
            defaults.email = cfg.acmeEmail;
            certs.${cfg.domain} = {
              domain = "*.${cfg.domain}";
              extraDomainNames = [ cfg.domain ];
              dnsProvider = "cloudflare";
              # Checks the challenge record against Cloudflare, not the local resolver
              dnsResolver = "1.1.1.1:53";
              environmentFile = config.sops.secrets.cloudflare-acme.path;
              group = config.services.caddy.group;
            };
          };
          # A renewal that keeps failing ends with every app's certificate expired
          systemd.services."acme-order-renew-${cfg.domain}".onFailure = [ "notify-failure@%n.service" ];

          services.caddy = {
            enable = true;
            virtualHosts =
              lib.mapAttrs' (
                name: a:
                lib.nameValuePair "${name}.${cfg.domain}" {
                  useACMEHost = cfg.domain;
                  extraConfig = signIn a + "reverse_proxy ${a.upstream}";
                }
              ) enabledApps
              // {
                ${cfg.domain} = {
                  useACMEHost = cfg.domain;
                  extraConfig = signIn cfg.apps.homepage + "reverse_proxy ${cfg.apps.homepage.upstream}";
                };
              };
          };

          networking.firewall.allowedTCPPorts = [
            80
            443
          ];
        })
      ]
    ))
  ];
}
