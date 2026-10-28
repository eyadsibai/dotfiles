# Omarchy user session (nixarchy): seeds ~/.config from Omarchy's defaults once,
# then leaves those files editable, as on Arch.
{ inputs, ... }:
{
  imports = [ inputs.nixarchy.homeManagerModules.nixarchy ];

  programs.nixarchy.enable = true;

  # greetd logs in automatically at boot (modules/nixos/desktop.nix), so lock the
  # first session of each boot as soon as the shell can draw the lock screen.
  # Later logins went through the greeter and are left alone.
  xdg.configFile."omarchy/hooks/post-boot.d/10-lock-after-autologin".text = ''
    marker="/tmp/omarchy-autolock-$USER-$(cat /proc/sys/kernel/random/boot_id)"
    [[ -e $marker ]] && exit 0
    touch "$marker"
    for _ in $(seq 30); do
      omarchy-system-lock
      sleep 1
      omarchy-hyprland-session-locked && exit 0
    done
    echo "Could not lock the session after autologin" >&2
    exit 1
  '';
}
