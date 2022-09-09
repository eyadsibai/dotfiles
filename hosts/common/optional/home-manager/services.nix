{ lib
, config
, pkgs
, ...
}: {
  # services.caffeine.enable = true;
  services.clipmenu.enable = false;
  services.dropbox.enable = true;
  services.espanso.enable = false;
  # services.fusuma.enable = true;
  # services.git-sync.enable = true;
  # services.gromit-mpx.enable = true;
  services.hound.enable = false;
}
