# CI

## GitHub Actions (always on)

`.github/workflows/check.yml` runs on every push:

- **eval**: every NixOS, macOS, and Home Manager configuration, without
  building (the runners can't build CUDA or macOS).
- **packages**: builds everything in `pkgs/`, so a re-released download with a new
  hash fails here instead of at the next switch.
- **format**: `nix fmt -- --ci`.

`update-flake-lock.yml` opens a PR with updated inputs every Monday.

## Nixbot on the workstation (parked)

Kept for later but switched off at the source: its flake input is commented out in
`flake.nix` and `modules/nixos/ci/nixbot.nix` isn't imported from
`modules/nixos/default.nix`, so no host loads it. Uncomment both (and run
`nix flake lock`) before the steps below.

`modules/nixos/ci/nixbot.nix` runs [nixbot](https://github.com/Mic92/nixbot) on the
workstation: it builds everything in `ciJobs` (every host, home, Arch system config
and package, see `flake.nix`) each time master moves, and
[Harmonia](https://github.com/nix-community/harmonia) serves the results as a binary
cache. Use it when GitHub's runners aren't enough: real builds of the CUDA-heavy
workstation and the aarch64 VMs, and hosts that upgrade from what CI built instead of
building it themselves (`my.autoUpgrade.from = "nixbot"`).

How it's set up:

- **Pull-based.** It polls `https://github.com/eyadsibai/dotfiles.git` every 5 minutes,
  so there's no GitHub App, webhook or open port.
- **Signed commits only.** A build only counts if its commit is signed with my 1Password
  key (the `verify-commit-signature` step), so a pushed commit I didn't sign never
  reaches a host.
- **Tailnet only.** The web UI is `http://workstation`, the cache `http://workstation:5000`,
  and the firewall opens both on `tailscale0` alone. Anyone on the tailnet can restart
  or cancel builds.
- **aarch64** builds run through QEMU (`boot.binfmt.emulatedSystems`). That's slow, but
  most of it comes from cache.nixos.org anyway.

### Turning it on

1. Make the cache's signing key:
   ```sh
   nix key generate-secret --key-name workstation-1 > /tmp/cache.key
   nix key convert-secret-to-public < /tmp/cache.key     # the public key, for step 3
   just secret nixbot                                     # cache-signing-key: |  (paste /tmp/cache.key)
   shred -u /tmp/cache.key
   ```
2. In `hosts/workstation/default.nix`: `my.ci.nixbot.enable = true;`, then `just switch`.
   Watch the first build at `http://workstation`.
3. On each host that should use the cache: `my.ci.useCache = true;` and
   `my.ci.cachePublicKey = "workstation-1:...";`. For home-server, also
   `my.autoUpgrade.from = "nixbot";`. It then takes the latest successful build of
   `ciJobs.hosts.home-server` from the cache (`cached-nixos-rebuild`, from Foundry)
   instead of building.
