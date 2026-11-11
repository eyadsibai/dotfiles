# Installing home-server

The services it runs, and setting them up after the install: [homelab.md](homelab.md).

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
- **Updated by hand**: `just deploy home-server` builds the system here and switches
  it over Tailscale, after a snapshot of the apps' state (homelab.md, Backups). It
  says when a new kernel or NVIDIA driver needs a reboot. Nothing on the server
  pulls code by itself, so only my SSH key can change it.
- **Secure Boot** once its keys exist (`my.secureBoot`, steps below).
- **Keeps going on its own**: a failed mount at boot carries on to SSH instead of an
  emergency shell nobody could log into, a hung kernel is rebooted by the hardware
  watchdog, and it never sleeps.

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

# The initrd's own SSH host key, for typing the passphrase remotely (step 3)
ssh-keygen -t ed25519 -N "" -f /tmp/hs/persist/etc/ssh/initrd_ssh_host_ed25519_key

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

## 3. Tailscale, then unlock with the TPM

Join the tailnet (`just deploy` and the domain's addresses go through it), and in
Tailscale's admin page turn off key expiry for home-server, or it drops off the
tailnet after six months:

```sh
ssh -A eyad@home-server
sudo tailscale up
```

Then bind the disk's key to the TPM:

```sh
sudo systemd-cryptenroll --wipe-slot=tpm2 --tpm2-device=auto \
  --tpm2-pcrs=0+7+15:sha256=0000000000000000000000000000000000000000000000000000000000000000 \
  /dev/disk/by-partlabel/disk-main-luks
```

From the next boot it unlocks by itself, as long as the firmware and Secure Boot state
(PCRs 0 and 7) are unchanged. PCR 15 must still be empty when the key is unsealed,
and the unlock itself fills it (`tpm2-measure-pcr` in disk.nix), so a disk swapped in
to imitate this one can't get the key afterwards. The passphrase still works as a
fallback. `--wipe-slot=tpm2` replaces an earlier enrolment rather than adding another.

Until Secure Boot is on (step 4), PCR 7 doesn't pin what boots: someone with the box
in hand can boot their own system and have the TPM unseal the key. The disk is
protected against a lost or discarded drive, not yet against a stolen machine.

If the TPM ever refuses (after a firmware update, say), the boot waits for the
passphrase, and it can be typed from another machine at home:
`ssh -p 2222 root@<its LAN address>`, then `systemd-tty-ask-password-agent`. Enroll the
TPM again afterwards. The initrd only has a network driver for common onboard chips
(`hosts/home-server/default.nix`); check that list against `nixos-generate-config`'s.

Check that a reboot unlocks by itself before relying on it: from then on a deploy
that brings a new kernel or NVIDIA driver can be finished with `sudo reboot` from
anywhere (Plex can't use the GPU until then).

## 4. Secure Boot (optional, later)

As root on the server: `sbctl create-keys`, then set `my.secureBoot.enable = true` in
`hosts/home-server/default.nix` and `just deploy home-server`. Check that `sbctl verify`
lists everything as signed, then put the firmware's Secure Boot in setup mode, run
`sbctl enroll-keys --microsoft`, reboot, and turn Secure Boot on. `bootctl status`
should say "Secure Boot: enabled (user)". Enroll the TPM again (step 3) so PCR 7
matches the new state.

## Day to day

`just deploy home-server` builds here and switches it over Tailscale; deploy it after
updating the desktops (`just update`, then `just switch`), so a flake.lock update that
breaks something breaks a desktop first. Deploy at least every few weeks, or it
misses security fixes.
