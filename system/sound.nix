{ pkgs, ... }: {
  environment.systemPackages = with pkgs;
    [
      easyeffects # optional for audio post processing
    ];

  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # services.shairport-sync.enable = true;
}
