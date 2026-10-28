# nixconfig-workstation

NixOS + Home Manager configuration for `workstation` (Intel, RTX 4090, GNOME).

## Layout

```
flake.nix                 inputs, the workstation system, formatter, dev shell
hosts/workstation/        machine-specific: hardware, NVIDIA/CUDA, boot, Tailscale routing
modules/nixos/            system level: nix, users, secrets, desktop, services, virtualisation
modules/nixos/ci/         optional: Buildkite agents (import from the host to enable)
modules/home/             Home Manager: shells, CLI tools, dev tools, desktop apps
secrets/                  sops-encrypted secrets (recipients in .sops.yaml)
```

Rule of thumb: anything that needs root, hardware, or a system daemon goes in
`modules/nixos`; everything else goes in Home Manager so it is portable to other hosts.
A module is enabled by importing it — there are no custom `enable` options.

## Usage

`direnv allow` once to get the dev shell (`nixfmt`, `nixd`, `just`, `nh`, `sops`).

| Command | Does |
|---|---|
| `just switch` | build, show package diff, activate |
| `just build` | build and show diff only |
| `just update` | update all flake inputs |
| `just check` | `nix flake check` |
| `just fmt` | format all Nix files |
| `just clean` | remove old generations, GC the store |
| `just secret <name>` | edit `secrets/<name>.yaml` |

## Secrets

Encrypted with sops-nix for two age recipients: the personal key in
`~/.config/sops/age/keys.txt` (keep a backup) and the machine's SSH host key.
