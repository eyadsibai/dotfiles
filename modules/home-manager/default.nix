# Add your reusable home-manager modules to this directory, on their own file (https://nixos.wiki/wiki/Module).
# These should be stuff you would like to share with others, not your personal configurations.
{
  # List your module files here
  # my-module = import ./my-module.nix;
  preferred-apps = import ./preferred-apps.nix;
  fonts = import ./fonts.nix;
  shellcolor = import ./shellcolor.nix;
  wallpaper = import ./wallpaper.nix;
}
