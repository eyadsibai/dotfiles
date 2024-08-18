{ pkgs, ... }: {
  programs.khard.enable = false;
  xdg.configFile."khard/khard.conf".text = ''
    [addressbooks]
    [[contacts]]
    path = ~/contacts/personal
  '';
}
