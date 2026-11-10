# The homelab on home-server

`modules/nixos/homelab`, switched on in `hosts/home-server` with `my.homelab.enable`.
Installing the machine itself: [home-server.md](home-server.md).

| File | What's in it |
|---|---|
| `default.nix` | The app registry, the domain, Caddy and the certificate |
| `storage.nix` | `/data`: data disks merged with mergerfs, SnapRAID parity |
| `platform.nix` | AdGuard Home, Homepage, Gatus, ntfy, Scrutiny, Pocket ID, btrfs snapshots |
| `backup.nix` | Nightly restic backups off-site, PostgreSQL dumps |
| `media.nix` | Plex, Seerr, Sonarr, Radarr, Lidarr, Prowlarr, Bazarr, Recyclarr, Pinchflat, Tautulli |
| `downloads.nix` | qBittorrent inside the VPN, SABnzbd |
| `apps.nix` | Miniflux, Karakeep, Paperless-ngx, Immich, Audiobookshelf |

## Adding a service

Put it in the file it belongs with (or a new one, imported from `default.nix`):

```nix
my.homelab.apps.mealie = {
  port = 9000;
  title = "Mealie";
  description = "Recipes";
  group = "Home";
  health = "/api/app/about";   # a path that answers without logging in
};
services.mealie = lib.mkIf (on "mealie") { enable = true; port = apps.mealie.port; };
```

From that entry it gets its address, a Homepage tile, a Gatus check (alerting on
ntfy), and once there's a domain, `https://mealie.<domain>`. Its state goes in
`/var/lib`, so the snapshots and the backup already include it. To switch any app off:
`my.homelab.apps.<name>.enable = false;`.

## Stages

Everything below is optional. Each step turns on more, and the machine works at every
stage.

### 0. Out of the box

Every app at `http://home-server:<port>`: Homepage at <http://home-server:8082> links to
the rest. Reachable on the LAN and over Tailscale, nothing from the internet. `/data`
is a folder on the NVMe until the disks are set up. qBittorrent stays off until the
VPN is set up, and Pocket ID until there's a domain.

### 1. Disks

`ls -l /dev/disk/by-id/` on the server, then in `hosts/home-server/default.nix`:

```nix
my.homelab.storage = {
  dataDisks = {
    disk1 = "/dev/disk/by-id/ata-...-part1";   # the Unraid array disks, as they are
    disk2 = "/dev/disk/by-id/ata-...-part1";
  };
  parityDisks.parity1 = "/dev/disk/by-id/ata-...-part1";
};
```

- The Unraid data disks are XFS, one filesystem each, and mount as they are. Any
  folders on them show up in `/data` straight away. Move them into the layout below
  with `mv` on the same disk, which is instant.
- Parity disks must be at least as big as the biggest data disk, and are formatted
  fresh: `sudo mkfs.xfs -L parity1 /dev/disk/by-id/...-part1`. Unraid's parity disk
  can't be reused, so format it the same way. Then run `sudo snapraid sync` once by
  hand. After that it runs nightly (`snapraid-sync.timer`), with a scrub weekly.
- Anything already in `/data` while it was on the NVMe (`/persist/data`) has to be
  copied over by hand.

Layout (hard links need downloads and library on the same filesystem):

```
/data/torrents/{incomplete,tv,movies,music}
/data/usenet/{incomplete,complete}
/data/media/{tv,movies,music,youtube,audiobooks,podcasts}
/data/photos                                   (Immich)
```

### 2. Secrets

1. The server's age key in `.sops.yaml` as `&home-server`, with a creation rule
   for `secrets/home-server.yaml` that includes it (home-server.md, step 1).
2. `just secret home-server`, with whichever keys the next stages need:

| Key | Contents | Used by |
|---|---|---|
| `cloudflare-acme` | `CF_DNS_API_TOKEN=...` (token with Zone → DNS → Edit on the zone) | the certificate |
| `pocket-id/encryption-key` | `openssl rand -base64 32` | Pocket ID |
| `vpn/wireguard.conf` | the provider's WireGuard file, as a `\|` block | qBittorrent's VPN |
| `restic/repository` | e.g. `s3:https://<account>.r2.cloudflarestorage.com/homelab` | backups |
| `restic/password` | long and random; **also in 1Password**, or the backup is unreadable | backups |
| `restic/env` | `AWS_ACCESS_KEY_ID=...` / `AWS_SECRET_ACCESS_KEY=...` lines | backups |
| `sonarr/api-key`, `radarr/api-key` | `openssl rand -hex 16` each | Sonarr, Radarr, Recyclarr |
| `pinchflat/env` | `SECRET_KEY_BASE=` + `openssl rand -hex 64` | Pinchflat |
| `miniflux/admin.env` | `ADMIN_USERNAME=...` / `ADMIN_PASSWORD=...` lines | Miniflux's first user |
| `paperless/admin-password` | a password | Paperless's `admin` user |
| `sabnzbd/secrets.ini` | `[servers]` sections for the Usenet provider | SABnzbd |

3. `my.homelab.secrets.enable = true;`. A key that's used must exist, or the switch
   fails and says which one is missing.

### 3. Domain and HTTPS

```nix
my.homelab = {
  domain = "home.example.com";
  acmeEmail = "...";
  lanAddress = "192.168.1.10";   # give it a fixed DHCP lease on the router
};
```

- **Cloudflare DNS**: `home` and `*.home` as A records pointing at home-server's
  Tailscale address (`tailscale ip -4`), proxy off (grey cloud). Away from home,
  devices on the tailnet reach it. The address is private, so it's useless to anyone
  else.
- **At home**: set the router's DHCP to hand out home-server's LAN address as DNS.
  AdGuard Home then answers `*.home...` with the LAN address, so phones reach the
  apps without Tailscale, and the whole house gets ad blocking. Keep a second DNS
  server off the router's list, or ads come back whenever a device picks that one.
- After the switch: Homepage at `https://<domain>`, each app at `https://<app>.<domain>`,
  and only ports 80 and 443 (plus Plex and DNS) open.
- Pocket ID comes up at `https://id.<domain>`: open `/setup` first to register the
  admin passkey. Immich, Paperless, Miniflux, Karakeep, Audiobookshelf and Seerr can
  sign in with it (OIDC, set in each app).

### 4. VPN for torrents

`vpn/wireguard.conf` from the provider (Proton or AirVPN for port forwarding), then
`my.homelab.vpn = { enable = true; forwardedPort = <port, or leave out>; };`.
Check it works: `sudo ip netns exec wg curl -s https://am.i.mullvad.net/ip` shows the
VPN's address, not home's.

### 5. Backups

The three `restic/*` keys, then `my.homelab.backup.enable = true;`. Nightly at 03:00.
Check: `sudo systemctl start restic-backups-homelab` and
`sudo restic-homelab snapshots`. Restoring: `sudo restic-homelab restore latest --target /tmp/r --include /var/lib/sonarr`.

## Connecting the apps (once, in their UIs)

- **Plex**: claim it from the server itself: `ssh -L 32400:localhost:32400 home-server`,
  then <http://localhost:32400/web>. Libraries: `/data/media/{tv,movies,music,youtube}`.
  Settings → Transcoder → *Use hardware acceleration* (the RTX 2070; needs Plex Pass).
- **qBittorrent**: first password from `journalctl -u qbittorrent`. Options →
  Downloads: save to `/data/torrents`, incomplete to `/data/torrents/incomplete`.
  Categories `tv`, `movies` and `music`, saving to `/data/torrents/<category>`.
- **SABnzbd**: the Usenet server (if not in secrets), and categories `tv`, `movies`
  and `music`.
- **Prowlarr**: add the indexers. Settings → Apps: Sonarr `http://127.0.0.1:8989`,
  Radarr `:7878`, Lidarr `:8686`, each with its API key. Indexers behind Cloudflare: add
  FlareSolverr (`http://127.0.0.1:8191`) as an indexer proxy with a tag.
- **Sonarr, Radarr, Lidarr**: root folder `/data/media/tv` (`movies`, `music`).
  Download clients: qBittorrent at `192.168.15.1:8090` and SABnzbd at `127.0.0.1:8085`
  (its API key is under Config → General). Media management: turn on *Use hard links*
  (it's on by default).
- **Bazarr**: connect to Sonarr and Radarr, then pick the subtitle languages and providers.
- **Seerr**: sign in with Plex, then connect it to Sonarr and Radarr.
- **Tautulli**: sign in with Plex.
- **Pinchflat**: add channels. They download into `/data/media/youtube`, so add that
  folder as a Plex library of type *Other videos*.
- **Miniflux** (without the secret): make the first user with
  `sudo systemd-run --pty -p User=miniflux -p DynamicUser=yes -E DATABASE_URL='user=miniflux host=/run/postgresql dbname=miniflux' miniflux -create-admin`.
  Import feeds: Settings → Import. Then newsboat can read from it: `urls-source "miniflux"`.
- **Paperless** (without the secret): `sudo paperless-manage createsuperuser`.
- **Immich, Karakeep, Audiobookshelf**: the first account made is the admin.
  Audiobookshelf's libraries: `/data/media/audiobooks` and `/data/media/podcasts`.
- **ntfy**: in the phone app, subscribe to `homelab` on the server's address. Failed
  backups, SnapRAID syncs and nightly upgrades, apps down for 6 minutes, and failing
  disks all land there.

## Later: smart home

Home Assistant, Mosquitto and Zigbee2MQTT all have NixOS modules
(`services.home-assistant`, `services.mosquitto`, `services.zigbee2mqtt`), and fit the
same pattern: a new `smart-home.nix`. It needs a Zigbee/Thread USB stick
(SONOFF ZBDongle-E, or SMLIGHT SLZB-06 over Ethernet). One choice to make then: run Home
Assistant as a NixOS service (declarative, no add-ons), or Home Assistant OS in a VM
(add-ons and its own updates).
