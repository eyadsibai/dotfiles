# eyad-nixos: AMD ThinkPad laptop, running the same Omarchy desktop as the workstation.
# Ported from the old dotfiles flake; only the hardware and laptop bits are host-specific.
{
  config,
  inputs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
    inputs.nixos-hardware.nixosModules.lenovo-thinkpad
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    ../../modules/nixos
    ../../modules/nixos/desktop.nix
  ];

  networking.hostName = "eyad-nixos";

  boot.supportedFilesystems = [ "ntfs" ];
  # Workarounds this ThinkPad needed for backlight, power states and NVMe latency
  boot.kernelParams = [
    "acpi_osi=Linux"
    "acpi_backlight=none"
    "processor.max_cstate=4"
    "iommu=soft"
    "idle=nomwait"
    "tpm_tis.interrupts=0"
    "nvme_core.default_ps_max_latency_us=250"
  ];
  boot.kernelModules = [ "acpi_call" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.acpi_call ];
  fileSystems."/".options = [ "noatime" ];

  hardware.enableRedistributableFirmware = true;
  hardware.trackpoint.enable = true;
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };
  # Omarchy drives power-profiles-daemon; set explicitly, as the ThinkPad profile
  # and nixarchy otherwise each pick TLP vs power-profiles-daemon from the other
  services.tlp.enable = false;
  services.power-profiles-daemon.enable = true;
  services.thermald.enable = true;
  services.fwupd.enable = true;
  services.fstrim.enable = true;
  services.libinput.touchpad.disableWhileTyping = true;

  home-manager.users.${username}.home.stateVersion = "22.05";

  system.stateVersion = "22.05";
}
