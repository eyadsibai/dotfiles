{ config
, pkgs
, lib
, username
, ...
}:
let
  sysConfig = config;
  homeConfig = config.home-manager.users.${username};

in
{
  home-manager.users.${username} = {
    services.easyeffects.enable = false;
  };
  # environment.systemPackages = with pkgs; [
  #   easyeffects
  #   # optional for audio post processing
  # ];
  security.rtkit.enable = true;
  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };
  # services.shairport-sync.enable = true;
}
