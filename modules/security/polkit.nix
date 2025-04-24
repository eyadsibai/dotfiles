{ lib, config, ... }:

let
  cfg = config.security.polkit;
in
{
  options.security.polkit = {
    enable = lib.mkEnableOption "Polkit (PolicyKit)";
    allowUserPowerManagement = lib.mkEnableOption "Allow users in 'users' group to reboot/shutdown without password";
  };

  config = lib.mkIf cfg.enable {
    security.polkit.enable = true;
    security.polkit.extraConfig = lib.mkIf cfg.allowUserPowerManagement ''
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
  };
}
