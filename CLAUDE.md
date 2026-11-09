# Working in this repo

My machines in one flake: NixOS (workstation, eyad-nixos, home-server, the Mac VMs
vm-fusion/vm-utm), nix-darwin (eyad-m3, eyad-mac), and Omarchy on Arch (vector, cachy:
Home Manager plus system-manager, the system itself stays pacman's). README.md is the
overview; docs/ has the longer procedures.

## Layout

- `flake.nix`: inputs, mkNixos / mkDarwin / mkArch / mkArchSystem, outputs.
- `hosts/<name>/`: what's specific to one machine. Shared things never live here.
- `modules/common` (Nix itself, binary caches), `modules/nixos`, `modules/darwin`,
  `modules/home` (Home Manager, every machine), `modules/arch-system` (root-owned
  files on Arch, through system-manager).
- `files/<package>/`: plain config linked into `~` from the checkout (not the store),
  per host via `my.files`. Editing `~/.config/...` on an Arch machine edits the repo.
- `pkgs/` (packages not in nixpkgs, as `pkgs.<name>` through `overlays/`), `overlays/`
  (also fixes to nixpkgs packages, each saying when it can go), `scripts/`, `arch/`.

## Checking a change

Nothing here can be switched from a session; check what can be checked:

- `nix fmt` after editing Nix files (nixfmt-tree; CI rejects unformatted files).
- Evaluate every configuration the change can reach. All of them:
  ```sh
  for a in nixosConfigurations.{workstation,eyad-nixos,home-server,vm-fusion,vm-utm}.config.system.build.toplevel \
           darwinConfigurations.eyad-m3.config.system.build.toplevel \
           'homeConfigurations."eyad@vector".activationPackage' 'homeConfigurations."eyad@cachy".activationPackage' \
           systemConfigs.vector; do nix eval --raw ".#$a.drvPath" >/dev/null || echo "FAILED: $a"; done
  ```
- On an Arch machine, build its own configs for real:
  `nix build --no-link '.#homeConfigurations."eyad@<host>".activationPackage' .#systemConfigs.<host>`.
- New files must be known to git (`git add -N`) or the flake can't see them.
- `files/tv` has tests: `uvx pre-commit run --files <changed files>`.
- Options that are off by default (`my.ci.*`, `my.secureBoot`, `my.autoUpgrade.from`)
  are checked by evaluating with them on through `extendModules`.

Say plainly what was evaluated, what was built, and what couldn't be tested (installs,
anything on the Macs, anything needing sudo).

## Conventions

- Comments say why, in plain sentences; the code says what.
- Arch: pacman owns programs, Home Manager only their config (`isArch`;
  `modules/home/pacman-bin.nix` for modules that insist on a package).
- Secrets: sops (`just secret <name>`) for system secrets, 1Password `op://`
  references for shell API keys. Never read decrypted secrets or put them in context.
- Never delete `*.hm-backup` files or anything under `~` that a switch moved aside;
  list them for me.

## Commits

`<area>: <what's different now>`, lowercase, no full stop, describing the result rather
than the action: `tv: x swaps the two TVs' windows instantly`, `arch: just switch puts
the root-owned files in place`. The area is the package, host or module (`tv`, `bar`,
`hypr`, `media`, `vector`, `arch`, `home-server`, `ci`). Only commit when asked.

### flake.lock updates

Summarise what changed upstream, not just the hashes. For each bumped input, take the
old and new revisions from the `nix flake update` output, read the changes between
them (`gh api repos/<owner>/<repo>/compare/<old>...<new>`), and list the ones that
matter in the commit body:

```
flake: update nixarchy and home-manager

nixarchy 1a2b3c4..5d6e7f8 (14 commits):
- Hyprland 0.52; window rules use the new syntax
- omarchy-theme-set runs app hooks in parallel
home-manager 9f8e7d6..0a1b2c3: programs.bat gains `themes` from files
```
