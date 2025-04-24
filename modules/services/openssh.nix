{ lib, config, ... }:

let
  cfg = config.services.openssh;
in
{
  options.services.openssh = {
    enable = lib.mkEnableOption "OpenSSH server";
    passwordAuthentication = lib.mkOption {
      type = lib.types.bool;
      default = false; # Default to false for better security
      description = "Whether to allow password authentication for SSH.";
    };
    x11Forwarding = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to allow X11 forwarding over SSH.";
    };
  };

  config = lib.mkIf cfg.enable {
    services.openssh = {
      enable = true;
      settings = {
        PasswordAuthentication = cfg.passwordAuthentication;
        X11Forwarding = cfg.x11Forwarding;
        # Add other settings as needed
      };
    };
  };
}
