# dotfiles

NixOS, macOS (nix-darwin) and Home Manager configuration for all my machines.

| Host | Kind | Notes |
|---|---|---|
| `workstation` | NixOS | Intel + RTX 4090 desktop, Omarchy desktop, Sunshine, Ollama; used remotely too |
| `eyad-nixos` | NixOS | AMD ThinkPad, same Omarchy desktop |
| `home-server` | NixOS | skeleton for the future Unraid replacement |
| `eyad-m3`, `eyad-mac` | macOS | one shared configuration, only the name differs |

The two Omarchy machines on Arch (`vector`, `cachy`) are not managed here yet.

## Layout

```
flake.nix               inputs, mkNixos / mkDarwin, every host, formatter, dev shell
hosts/<name>/           per machine: hardware, boot, what that machine is for
hosts/mac/              the configuration all Macs share
modules/common/         settings for both NixOS and macOS (Nix, caches)
modules/nixos/          NixOS: default.nix is shared by every NixOS host;
                        desktop.nix, sunshine.nix, virtualisation.nix, ai.nix are opt-in
modules/darwin/         macOS: system defaults, Homebrew, apps
modules/home/           Home Manager, shared by every host (shells, CLI, dev tools,
                        1Password SSH agent); desktop-apps.nix and omarchy.nix are Linux-only
secrets/                sops-encrypted secrets (recipients in .sops.yaml)
```

Rule of thumb: anything that needs root, hardware, or a system daemon goes in
`modules/nixos` or `modules/darwin`; everything else goes in Home Manager so every
machine gets it. Optional modules are enabled by importing them; the few custom
options live under `my.*` (e.g. `my.desktop.autoLogin`).

The Omarchy desktop comes from [nixarchy](https://github.com/olafkfreund/nixarchy),
pinned to a release tag. Bump it on purpose, after the Arch machines run the same
Omarchy version, and try it first with `just vm`.

## Usage

Clone to `~/dev/dotfiles` (the path `nh` and Omarchy's Update menu use), then
`direnv allow` once for the dev shell (`nixfmt`, `nixd`, `just`, `nh`, `sops`).

| Command | Does |
|---|---|
| `just switch [host]` | build, show package diff, activate (NixOS or macOS) |
| `just build [host]` | build and show the diff only |
| `just boot [host]` | NixOS: activate on next boot (use when changing the desktop/login) |
| `just vm [host]` | NixOS: boot the configuration in a throwaway VM |
| `just update` | update all flake inputs |
| `just check` | `nix flake check` |
| `just fmt` | format all Nix files |
| `just clean` | remove old generations, GC the store |
| `just secret <name>` | edit `secrets/<name>.yaml` |

`host` defaults to this machine's name.

## Secrets

Encrypted with sops-nix for age recipients: the personal key in
`~/.config/sops/age/keys.txt` (backed up in 1Password as "sops age key —
workstation") and each machine's SSH host key.
