{ lib, config, ... }:

let
  cfg = config.services.pipewire;
in
{
  options.services.pipewire = {
    enable = lib.mkEnableOption "Pipewire audio service";
    alsa.enable = lib.mkEnableOption "ALSA support for Pipewire";
    alsa.support32Bit = lib.mkEnableOption "32-bit ALSA support";
    pulse.enable = lib.mkEnableOption "PulseAudio compatibility for Pipewire";
    jack.enable = lib.mkEnableOption "JACK compatibility for Pipewire"; # Added JACK option
  };

  config = lib.mkIf cfg.enable {
    # Ensure pulseaudio is disabled if pipewire is enabled
    services.pulseaudio.enable = false;
    security.rtkit.enable = true; # Often needed for real-time audio

    services.pipewire = {
      enable = true;
      alsa.enable = cfg.alsa.enable;
      alsa.support32Bit = cfg.alsa.support32Bit;
      pulse.enable = cfg.pulse.enable;
      jack.enable = cfg.jack.enable; # Enable JACK support via option
    };
  };
}
