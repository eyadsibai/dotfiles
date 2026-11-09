# Installing home-server

`hosts/home-server` is built to run with nobody at it:

- **Encrypted disk, unlocked by the TPM.** One LUKS partition holding btrfs
  (`hosts/home-server/disk.nix`). Until the TPM is enrolled it asks for the passphrase at
  boot, so the first boots need a screen and keyboard.
- **A root that starts empty on every boot.** `/` is rolled back to a blank snapshot in
  the initrd. What survives sits on its own subvolumes: `/nix`, `/home`, `/var/lib` (all
  service state), `/var/log`, and `/persist` for single files like the SSH host key and
  `/etc/machine-id`. Anything else written to `/` is gone after a reboot, so the machine
  can't drift from its config. To keep the root for one boot while investigating, mount
  the top-level subvolume and `touch dont-wipe` in it.
- **No passwords.** Users come only from the config (`users.mutableUsers = false`), you
  log in with SSH keys, and sudo is approved through the forwarded SSH agent (`ssh -A`,
  so 1Password on the machine you're sitting at).
- **Upgrades itself** every night at 04:00 from `github:eyadsibai/dotfiles`
  (`my.autoUpgrade`), or from the self-hosted CI's builds (docs/ci.md).
- **Secure Boot** once its keys exist (`my.secureBoot`, steps below).

## 1. Prepare

On the machine, boot the NixOS installer ISO, then:

```sh
sudo passwd root          # temporary, for nixos-anywhere
lsblk                     # the disk; set disko.devices.disk.main.device if not /dev/nvme0n1
ip a                      # its address
nixos-generate-config --show-hardware-config --no-filesystems   # compare the kernel modules
```

On your machine, in the repo:

```sh
# The SSH host key, made here so sops can encrypt to it before the install
mkdir -p /tmp/hs/persist/etc/ssh
ssh-keygen -t ed25519 -N "" -f /tmp/hs/persist/etc/ssh/ssh_host_ed25519_key
nix shell nixpkgs#ssh-to-age -c ssh-to-age < /tmp/hs/persist/etc/ssh/ssh_host_ed25519_key.pub
#   add that age key to .sops.yaml as &home-server, then `sops updatekeys secrets/*.yaml`

# The disk passphrase, also saved in 1Password
read -s pass; printf %s "$pass" > /tmp/disk.key
```

## 2. Install

```sh
ssh-copy-id root@<ip>
nix run --inputs-from . nixpkgs#nixos-anywhere -- --flake .#home-server \
  --disk-encryption-keys /tmp/disk.key /tmp/disk.key \
  --extra-files /tmp/hs \
  --target-host root@<ip>
shred -u /tmp/disk.key; rm -rf /tmp/hs
```

It partitions and encrypts the disk, installs, and reboots. Type the passphrase at the
console.

## 3. Unlock with the TPM

```sh
ssh -A eyad@home-server
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/disk/by-partlabel/disk-main-luks
```

From the next boot it unlocks by itself, as long as the firmware and Secure Boot state
(PCRs 0 and 7) are unchanged. The passphrase still works as a fallback.

## 4. Secure Boot (optional, later)

As root on the server: `sbctl create-keys`, then set `my.secureBoot.enable = true` in
`hosts/home-server/default.nix` and `just deploy home-server`. Check that `sbctl verify`
lists everything as signed, then put the firmware's Secure Boot in setup mode, run
`sbctl enroll-keys --microsoft`, reboot, and turn Secure Boot on. `bootctl status`
should say "Secure Boot: enabled (user)". Enroll the TPM again (step 3) so PCR 7
matches the new state.

## Day to day

`just deploy home-server` builds here and switches it over Tailscale. The nightly
upgrade picks up whatever is on master, so a pushed change lands by the next morning
without either.
