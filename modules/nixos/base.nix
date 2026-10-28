{ pkgs, ... }:
{
  time.timeZone = "Asia/Riyadh";
  i18n.defaultLocale = "en_US.UTF-8";
  services.xserver.xkb.layout = "us";

  networking.networkmanager.enable = true;

  # Always-on machine: never sleep
  systemd.targets.sleep.enable = false;
  systemd.targets.suspend.enable = false;
  systemd.targets.hibernate.enable = false;
  systemd.targets.hybrid-sleep.enable = false;

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
  # Kept at system level: it exports SSH_AUTH_SOCK to the whole desktop session,
  # not just shells (Home Manager's gpg-agent only reaches shells)
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # Populate /bin and /usr/bin for scripts with hard-coded paths
  services.envfs.enable = true;

  # Minimal toolset for root; everything else is per-user in Home Manager
  environment.systemPackages = [ pkgs.git ];
}
