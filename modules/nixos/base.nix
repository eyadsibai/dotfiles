{ pkgs, ... }:
{
  boot.loader.systemd-boot = {
    enable = true;
    editor = false; # no editing kernel parameters (e.g. init=/bin/sh) at the boot menu
    configurationLimit = 10; # boot-menu rollback targets
  };
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "Asia/Riyadh";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  networking.networkmanager.enable = true;

  # Let local users reboot / power off without a password
  security.polkit.enable = true;
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (
        subject.isInGroup("users")
          && (
            action.id == "org.freedesktop.login1.reboot" ||
            action.id == "org.freedesktop.login1.reboot-multiple-sessions" ||
            action.id == "org.freedesktop.login1.power-off" ||
            action.id == "org.freedesktop.login1.power-off-multiple-sessions"
          )
        )
      {
        return polkit.Result.YES;
      }
    })
  '';

  # Keep the root disk tidy: cap the journal (it had grown to 4 GB) and empty /tmp on boot
  services.journald.settings.Journal.SystemMaxUse = "1G";
  boot.tmp.cleanOnBoot = true;

  services.printing.enable = true;

  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.zsh.enable = true;
  # Run unpatched dynamic binaries (e.g. downloaded tools, pip wheels)
  programs.nix-ld.enable = true;
  # GPG agent for signing/encryption only; SSH keys come from 1Password's agent,
  # which SSH finds through ~/.ssh/config (modules/home/onepassword.nix)
  programs.gnupg.agent.enable = true;

  # Populate /bin and /usr/bin for scripts with hard-coded paths
  services.envfs.enable = true;

  # Minimal toolset for root; everything else is per-user in Home Manager
  environment.systemPackages = [ pkgs.git ];
}
