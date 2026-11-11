# The homelab on home-server

`modules/nixos/homelab`, switched on in `hosts/home-server` with `my.homelab.enable`.
Installing the machine itself: [home-server.md](home-server.md).

| File | What's in it |
|---|---|
| `default.nix` | The app registry, the domain, Caddy and the certificate |
| `storage.nix` | `/data`: encrypted data disks merged with mergerfs, SnapRAID parity, spin-down, fans |
| `platform.nix` | AdGuard Home, Homepage, Gatus, ntfy, Scrutiny, Beszel, Pocket ID, btrfs snapshots |
| `backup.nix` | Nightly restic backups, off-site and on the data disks; PostgreSQL dumps |
| `shares.nix` | Samba: `/data`, Time Machine, Paperless's scanner inbox |
| `media.nix` | Plex, Jellyfin, Navidrome, Seerr, Sonarr, Radarr, Lidarr, Prowlarr, Bazarr, Recyclarr, Pinchflat, Tautulli |
| `downloads.nix` | qBittorrent inside the VPN, SABnzbd |
| `apps.nix` | Miniflux, Karakeep, Paperless-ngx, Immich, Audiobookshelf |
| `gaming.nix` | Wolf: Steam, RetroArch and other games streamed to Moonlight on any screen |
| `auth.nix` | The passkey sign-in in front of the admin pages |

`tests/homelab.nix` boots it in a VM with blank disks and checks the disks, SnapRAID
and that every app answers: `nix build .#checks.x86_64-linux.homelab -L`. Worth
running after changing `storage.nix` or adding an app.

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

Every data and parity disk is encrypted, all with one key: `storage/disk-key` in the
secrets (`openssl rand -hex 64`), so this stage comes after stage 2. The key is
backed up with the repo, encrypted to my age key; without it the disks can't be read.
They unlock at boot without anyone there, after the NVMe. A disk sent back under
warranty or thrown away then gives nothing away, the photos and Time Machine backups
included.

`ls -l /dev/disk/by-id/` on the server. A new disk (or one whose files have been
copied off) is formatted with `sudo data-disk-prepare /dev/disk/by-id/<whole disk>`:
one partition, LUKS, XFS inside. It prints the line to add in
`hosts/home-server/default.nix`:

```nix
my.homelab.storage = {
  dataDisks = {
    disk1 = "/dev/disk/by-id/ata-...-part1";
    disk2 = "/dev/disk/by-id/ata-...-part1";
  };
  parityDisks.parity1 = "/dev/disk/by-id/ata-...-part1";
};
```

**Moving the Unraid disks across.** They hold plain XFS. Listed in
`storage.plainDisks = [ "disk1" ... ];` they mount as they are, and their files show
up in `/data` straight away. To encrypt them, each one's files move to an encrypted
disk in turn, which needs one empty disk at least as big as the biggest of them.
The new parity disk works, before it becomes parity:

1. Install with every Unraid data disk in `dataDisks` and `plainDisks`, and no parity
   yet. Check the files are all there.
2. `data-disk-prepare` the empty disk and add it as a data disk (`disk5`, say).
3. With nothing downloading, copy the first Unraid disk onto it, hard links and all:
   `sudo rsync -aHAX --info=progress2 /mnt/disk1/ /mnt/disk5/`. Compare
   (`sudo rsync -naHAX --delete /mnt/disk1/ /mnt/disk5/` lists nothing), then take
   `disk1` out of the config and switch. `/data` looks the same throughout.
4. `data-disk-prepare` the old disk1, add it back as an empty data disk, and repeat
   from 3 with the next Unraid disk copied onto it.
5. The last disk to be emptied becomes the parity disk: `data-disk-prepare` it, list
   it in `parityDisks`, and `sudo snapraid sync`.

Unraid's parity disk can't be reused as it is: `data-disk-prepare` it too. **No way
back to Unraid** once a disk has been written to here, since Unraid's parity no longer
matches. To look around first, add `options = [ "ro" ];` for the disks in
`hosts/home-server`.

- If a disk is missing at boot, `/data` isn't mounted (after a minute's wait) and
  everything that uses it stays stopped, rather than writing into the NVMe under it.
  ntfy and Gatus report the apps as down.
- Parity disks must be at least as big as the biggest data disk. Run
  `sudo snapraid sync` once by hand after adding one. After that it runs nightly (`snapraid-sync.timer`), with a scrub weekly.
  If more than 500 files (`storage.deleteThreshold`) were deleted since the last
  sync, the nightly sync stops and says so on ntfy instead of making the deletion
  permanent: `sudo snapraid diff` to see what went, `sudo snapraid fix -m` to bring
  it back, or `sudo snapraid sync` if it was meant. Time Machine, the local backup
  and Immich's thumbnails are left out of parity: they change every night.
- Anything already in `/data` while it was on the NVMe (`/persist/data`) has to be
  copied over by hand.
- The `media` group is gid 2000 on every install, so ownership on the disks still
  matches after a reinstall. Files Unraid wrote belong to `nobody:users` (99:100); if an
  app can't rename one, `sudo chgrp -R media /data/media && sudo chmod -R g+w /data/media`.
- The disks spin down after 30 idle minutes (`storage.spinDownMinutes`, 0 for never).
  For the case fans to follow the disks' temperature, find the fan's PWM file with
  `nix run nixpkgs#lm_sensors -- pwmconfig` and set
  `storage.fanPwmPaths = [ "/sys/class/hwmon/hwmonN/pwmM:<start>:<stop>" ];`.

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
| `storage/disk-key` | `openssl rand -hex 64`; **also in 1Password** | unlocking the data disks |
| `pocket-id/encryption-key` | `openssl rand -base64 32` | Pocket ID |
| `vpn/wireguard.conf` | the provider's WireGuard file, as a `\|` block | qBittorrent's VPN |
| `restic/repository` | e.g. `s3:https://<account>.r2.cloudflarestorage.com/homelab` | backups |
| `restic/password` | long and random; **also in 1Password**, or the backup is unreadable | backups |
| `restic/env` | `AWS_ACCESS_KEY_ID=...` / `AWS_SECRET_ACCESS_KEY=...` lines | backups |
| `sonarr/api-key`, `radarr/api-key`, `lidarr/api-key`, `prowlarr/api-key`, `sabnzbd/api-key` | `openssl rand -hex 16` each | the apps, Recyclarr, connecting them to each other |
| `pinchflat/env` | `SECRET_KEY_BASE=` + `openssl rand -hex 64` | Pinchflat |
| `miniflux/admin.env` | `ADMIN_USERNAME=...` / `ADMIN_PASSWORD=...` lines | Miniflux's first user |
| `paperless/admin-password` | a password | Paperless's `admin` user |
| `sabnzbd/secrets.ini` | `[servers]` sections for the Usenet provider | SABnzbd |
| `samba/password` | a password | the shares, signed in as `eyad` |
| `heartbeat-url` | the ping URL of a healthchecks.io check (5 minute period) | noticing the server is down |
| `tinyauth/env`, `tinyauth/client-secret` | from Pocket ID, once it runs (stage 3) | the sign-in in front of the admin pages |
| `miniflux/oidc-client-id`, `miniflux/oidc-client-secret` | from Pocket ID (stage 3) | Miniflux signing in with a passkey |
| `paperless/oidc-client-id`, `paperless/oidc-client-secret` | from Pocket ID (stage 3) | Paperless signing in with a passkey |

3. `my.homelab.secrets.enable = true;`. A key that's used must exist, or the switch
   fails and says which one is missing.

The shares come with the secrets (`my.homelab.shares.enable = false;` to leave them
off), reachable from home and the tailnet only:

- `smb://home-server/data`: all of `/data`. New files land in the `media` group, so
  the apps can rename them.
- **Time Machine**: on each Mac, System Settings → General → Time Machine → Add Backup
  Disk shows `timemachine` on home-server. Each Mac may use up to
  `shares.timeMachineSize` (1 TB) before old backups go.
- `smb://home-server/scans`: Paperless takes in whatever is saved there. Scanners
  that only speak SMB1 can't reach it; have them email or use the Paperless app instead.

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
- After the switch: Homepage at `https://<domain>`, each app at `https://<app>.<domain>`.
  The apps' own ports close; what stays open is SSH, HTTP and HTTPS, DNS, Plex, the
  shares (Samba, Bonjour, WS-Discovery) and Wolf's streaming ports.
- The server itself resolves names through Quad9 and Cloudflare, not its own AdGuard,
  so it keeps upgrading, renewing and backing up if AdGuard is down.
- Pocket ID comes up at `https://id.<domain>`: open `/setup` first to register the
  admin passkey. Immich, Audiobookshelf, Karakeep and Beszel can sign in with it from
  their settings. Seerr can't: upstream has no OIDC yet, so it signs in through Plex.
- **Miniflux and Paperless with a passkey** are set in the config: in Pocket ID add a
  client `miniflux` with callback `https://miniflux.<domain>/oauth2/oidc/callback`,
  and one `paperless` with callback
  `https://paperless.<domain>/accounts/oidc/pocketid/login/callback/`; put each one's
  id and secret in sops (table above), then
  `my.homelab.apps.miniflux.oidc = true;` (and `paperless`). The existing account
  links to it once, while signed in the old way: Miniflux under Settings → *Link my
  Pocket ID account*, Paperless under the profile's *Connect* button. The password
  sign-in stays as a way in if Pocket ID is down.
- **One sign-in for the admin pages** (the *arr apps, the download clients, AdGuard,
  Gatus, Scrutiny, Homepage): in Pocket ID add an OIDC client `tinyauth` with
  callback `https://auth.<domain>/api/oauth/callback/pocketid`; put its secret in
  sops as `tinyauth/client-secret` and its id as `tinyauth/env`
  (`TINYAUTH_OAUTH_PROVIDERS_POCKETID_CLIENTID=<id>`); then
  `my.homelab.apps.auth.enable = true;`. Those pages then ask for the passkey first.
  The apps' own logins stay as a second lock. AdGuard has no login of its own, so
  until then its page is open to the LAN and tailnet.
- A daily check confirms the certificate has more than 10 days left and that AdGuard
  answers with the LAN address, so a broken renewal or DNS shows up on ntfy.

### 4. VPN for torrents

`vpn/wireguard.conf` from the provider, then
`my.homelab.vpn = { enable = true; forwardedPort = <port, or leave out>; };`.
It needs a provider that gives a WireGuard config file. `forwardedPort` is for one
that forwards a fixed port to you, so peers can connect in: AirVPN does, set once in
its client area. Without one, torrents still work, with fewer peers. Providers that
lease a changing port instead (Proton over NAT-PMP, PIA through its API) would need a
loop renewing it, which isn't here; Mullvad and IVPN no longer forward ports at all.
Check it works: `sudo ip netns exec wg curl -s https://am.i.mullvad.net/ip` shows the
VPN's address, not home's.

### 5. Backups

The three `restic/*` keys, then `my.homelab.backup.enable = true;`. Off-site nightly
at 03:00; once there are data disks, a second copy goes to `/data/backups/restic` at
02:45, for restoring quickly after the NVMe dies. Check: `sudo systemctl start
restic-backups-homelab` and `sudo restic-homelab snapshots` (`restic-local` for the
local one). Restoring: `sudo restic-local restore latest --target /tmp/r --include /var/lib/sonarr`.

Each backup reads a read-only snapshot of `/var/lib`, `/persist` and `/home` taken just
before it, so the apps' databases are copied whole, never mid-write. Paperless also
writes its own export (documents and their metadata) to `/var/lib/paperless/export`
nightly, which is what its docs say to restore from. On the 1st of each month a part
of the off-site backup is restored and checked, and ntfy hears if that fails.

Before each nightly upgrade btrbk takes a snapshot of the state, because rolling NixOS
back doesn't undo what a new version of an app did to its database. To go back:
`ls /mnt/btr-pool/snapshots`, stop the app, and copy its folder back from the
snapshot taken before the upgrade.

The healthchecks.io check (`heartbeat-url`) emails or notifies when the server stops
checking in for 5 minutes: the one alert that doesn't need the server to be up.

## Connecting the apps (once, in their UIs)

- **Plex**: claim it from the server itself: `ssh -L 32400:localhost:32400 home-server`,
  then <http://localhost:32400/web>. Libraries: `/data/media/{tv,movies,music,youtube}`.
  Settings → Transcoder → *Use hardware acceleration* (the RTX 2070; needs Plex Pass).
  Settings → Library: turn off *Empty trash automatically after every scan*, so a
  missing disk doesn't empty the library. Streaming away from home needs Plex Pass
  (or Plex's Remote Watch Pass) since 2025. The GPU encodes at most 8 streams at
  once, Plex's and Wolf's together.
- **qBittorrent**: first password from `journalctl -u qbittorrent`. Options →
  Downloads: save to `/data/torrents`, incomplete to `/data/torrents/incomplete`.
  Categories `tv`, `movies` and `music`, saving to `/data/torrents/<category>`.
- **SABnzbd**: the Usenet server (if not in secrets), and categories `tv`, `movies`
  and `music`.
- **Prowlarr**: add the indexers. With the secrets, Sonarr, Radarr and Lidarr are
  already connected under Settings → Apps (`arr-wiring.service`); without them, add
  each with its URL and API key. Indexers behind Cloudflare: add FlareSolverr
  (`http://127.0.0.1:8191`) as an indexer proxy with a tag.
- **Sonarr, Radarr, Lidarr**: root folder `/data/media/tv` (`movies`, `music`). With
  the secrets SABnzbd is already their download client; add qBittorrent at
  `192.168.15.1:8090` with its password. Quality profiles: pick *WEB-1080p* (Sonarr)
  and *HD Bluray + WEB* (Radarr), which Recyclarr keeps in step with the TRaSH Guides.
  Media management: *Use hard links* is on by default.
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
- **Jellyfin**: the first visit sets up the admin. Libraries from `/data/media`.
  Transcoding on the GPU is set already (NVENC); Dashboard → Playback shows it. It
  shares the GPU's 8-stream limit with Plex and Wolf.
- **Navidrome**: the first visit makes the admin; it scans `/data/media/music`. On the
  phone, a Subsonic app (Symfonium on Android, Amperfy or play:Sub on iOS) with the
  server's address and that account.
- **Beszel**: the first visit makes the admin. Then *Add system*: name home-server,
  host `127.0.0.1`, port `45876`; copy the public key it shows into
  `my.homelab.beszelKey` in `hosts/home-server/default.nix`, and switch. It keeps CPU, memory, disk, GPU and
  temperature history, and can alert on thresholds.
- **ntfy**: in the phone app, subscribe to `homelab` on the server's address. Failed
  backups (both copies and the database dump), snapshots, SnapRAID syncs and scrubs,
  certificate renewals, nightly upgrades (including a master it refused as unsigned),
  Wolf giving up, apps down for 6 minutes, and failing disks all land there.

## Games

Wolf makes the server a console for every screen in the house. A device running
Moonlight connects and gets its own virtual screen, sound and controllers on the GPU;
two rooms can play different things at once. Nothing is plugged into the server.

- **Clients**: Moonlight, from the Play Store on Android TV, Google TV and phones, and
  on the Macs. Wired network where possible. Controllers pair with the device in front
  of you, not with the server.
  - **Shield TV** is what most people use, and handles several controllers best.
  - **Chromecast / Google TV**: in Moonlight's settings, turn off its power saving, or
    it feels far laggier than its stats say.
  - **LG TV**: moonlight-tv (webOS, installed with webOS Dev Manager). If the picture
    breaks up, lower the MTU on the TV's connection to 1428.
  - **Samsung TV**: moonlight-tizen works, but its maintainer has said 2026 is its
    last year of active development; an Android TV stick in that room lasts longer.
  - **Over Tailscale**: add the server by its address (discovery doesn't cross the
    tailnet), and check `tailscale status` says *direct*, not relayed.
- **Pairing a device** (once each): on the LAN, Moonlight may list the server as `wolf`;
  otherwise add `home-server` by hand. It shows a PIN. Wolf logs the page to type it into:
  `ssh home-server journalctl -u podman-wolf -o cat -g 'Insert pin' | tail -1`.
  With a domain the same page is at `https://wolf.<domain>/pin/#<the code in that line>`.
- **Playing**: start *Wolf UI*, pick a profile, pick an app. Greyed-out apps are
  fetched when chosen: Steam, RetroArch, ES-DE, Pegasus, Lutris, Heroic, Prism
  Launcher, Kodi, Firefox. A black screen with a cursor means an image is still
  downloading (`journalctl -fu podman-wolf`). Back to the menu from inside a game:
  Start + Up + RB, or Ctrl+Alt+Shift+W.
- **Steam**: sign in once per profile. Games install into that profile's folder,
  `/etc/wolf/profile_data/<profile>/`, on the NVMe. In Proton games, if the sound
  moves to another room when a second person connects (wolf#460), set the game's Wine
  registry key `HKCU\Software\Wine\PulseAudio` → `Device` to `$PULSE_SINK`.
- **ROMs**: `/data/roms/<system>` (`snes`, `psx`, `gba`, ...; Pegasus and ES-DE expect
  one folder per system under `/ROMs`). Each emulator app needs the folder mounted:
  add `"/data/roms:/ROMs:ro"` to its `mounts` in `/etc/wolf/cfg/config.toml`
  ([Wolf's configuration page](https://games-on-whales.github.io/wolf/stable/user/configuration.html)),
  then `sudo systemctl restart podman-wolf`. Wolf owns that file (it adds each paired
  device to it), so it's edited in place rather than written from here.
- **BIOS files** for the consoles that need them: `/data/roms/bios`, mounted at both
  `/bioses` and `/home/retro/bioses` (the images disagree on where they look):
  `"/data/roms/bios:/bioses:ro", "/data/roms/bios:/home/retro/bioses:ro"`. The images
  have RetroArch, PCSX2, Dolphin, xemu, RPCS3, Cemu and Xenia, but no Switch emulator;
  RetroArch's cores are fetched per profile with its Online Updater.
- **Profiles**: one each for whoever plays, with a PIN where wanted, also in
  `config.toml`. Every profile has its own Steam login, saves and settings.
- **Updates**: Wolf is a fixed release, `my.homelab.gaming.version` (v2026.11); bump
  it on purpose after reading the release notes. The apps update from Wolf UI. After
  an NVIDIA driver update the first boot rebuilds the driver volume the apps use,
  which takes a few minutes and needs the internet (it retries for half an hour);
  ntfy says so if it fails.
- **Several rooms at once** is Wolf's least settled part on NVIDIA. Frames are copied
  between the game and the encoder (`gaming.zeroCopy = false`): the faster path has
  broken other rooms' streams when one ended. Wolf itself is capped at 4 GB
  (`gaming.memoryLimit`), since that path has leaked memory before. If Wolf can't
  load NVIDIA's encoder it encodes on the CPU, which ntfy is told about.
- **Not there**: HDR, and AV1 (the 2070 can't encode it).
- **A second GPU** (a CPU with graphics of its own): Wolf may pick that one. Set
  `my.homelab.gaming.renderNode` to the card `ls -l /sys/class/drm/renderD*/device/driver`
  shows for nvidia.
- **Backups**: `/etc/wolf` is backed up with the rest, minus the games Steam
  installed. Other launchers' installs are not left out; add them to the backup's
  excludes if they grow. It isn't in the hourly snapshots.

Wolf and its apps are containers, and Wolf starts the apps through Podman's socket,
so it can do anything root can. Its image is pinned by release tag, not by
`flake.lock` like the rest: `my.homelab.apps.wolf.enable = false;` if that's not wanted.

The workstation's Sunshine is still there for what needs the 4090. It shows up in
Moonlight as a second host, over Tailscale only.

## Later: smart home

Home Assistant, Mosquitto and Zigbee2MQTT all have NixOS modules
(`services.home-assistant`, `services.mosquitto`, `services.zigbee2mqtt`), and fit the
same pattern: a new `smart-home.nix`. It needs a Zigbee/Thread USB stick
(SONOFF ZBDongle-E, or SMLIGHT SLZB-06 over Ethernet). One choice to make then: run Home
Assistant as a NixOS service (declarative, no add-ons), or Home Assistant OS in a VM
(add-ons and its own updates).
