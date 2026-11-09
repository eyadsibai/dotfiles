# A NixOS VM on the Mac

`vm-fusion` (VMware Fusion) and `vm-utm` (UTM) are the same aarch64 NixOS with GNOME,
logged in automatically, with this repo's shell, CLI, git and 1Password setup. The Mac's
shared folders appear at `/host`, and x86_64 binaries run through QEMU.

1. Create the VM: UEFI, the aarch64 NixOS ISO, most of the cores and RAM. Fusion: a SATA
   disk (`/dev/sda`) and 3D acceleration on. UTM: the QEMU backend (not "Use Apple
   Virtualization") and a VirtIO disk (`/dev/vda`).
2. In the VM's console: `sudo passwd root`, and note its address (`ip a`).
3. On the Mac, in this repo: `ssh-copy-id root@<ip>`, then `just vm-install vm-utm <ip>`
   (or `vm-fusion`). nixos-anywhere partitions the disk with the layout in
   `modules/nixos/vm-guest.nix`, builds the system on the Mac's Linux builder, installs
   it and reboots.
4. In the VM: sign in to 1Password, clone this repo to `~/dev/dotfiles`, and from then on
   `just switch` there like on any other host.

A new Mac can be set up the same way from an existing one: `just mac-copy <name> <user>@<ip>`
builds that Mac's system here and copies it over, so its first switch downloads nothing.
