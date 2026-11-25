# CI

## GitHub Actions (always on)

`.github/workflows/check.yml` runs on every push:

- **eval**: every NixOS, macOS, and Home Manager configuration, the homelab VM test,
  the full-stage `home-server` evaluation, and the `arch/nix.conf` cache sync check,
  without building (the runners can't build CUDA or macOS). The list is `evalTargets`
  in `flake.nix`, the same one `just check` evaluates, so a new host is picked up by itself.
- **packages**: builds everything in `pkgs/`, so a re-released download with a new
  hash fails here instead of at the next switch.
- **format & lint**: `nix fmt -- --ci`, `statix`, `deadnix`, `shellcheck`, and `ruff`.
- **plugin-tests**: runs the `eyad.meetplanner` unit tests.

`homelab.yml` boots the homelab in a VM (`tests/homelab.nix`) when the homelab
modules, the test, `flake.nix` or `flake.lock` change.

`tv.yml` runs `files/tv`'s tests when they change.

Inputs are updated by hand (`just upgrade`), not by a scheduled PR: the lock moves
most days anyway, and the weekly PRs were only ever closed.

## Buildkite on the workstation (opt-in)

`modules/nixos/ci/buildkite.nix` defines two Buildkite agents (`it-1`, `it-2`) for
running integration tests on `workstation` (with RTX 4090 access and CPU/memory caps).
It isn't imported by default; to enable it, create `secrets/buildkite.yaml`
(`just secret buildkite` with `agent-token` and `ssh-key`) and import
`../../modules/nixos/ci/buildkite.nix` from `hosts/workstation/default.nix`.
