{ pkgs, ... }: {
  imports =
    [ ./fonts.nix ./media.nix ./office.nix ./services.nix ./development.nix ];
}
