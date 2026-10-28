# UTM virtual machines (the app from Homebrew, qemu for disk images)
{ pkgs, ... }:
{
  homebrew.casks = [ "utm" ];
  environment.systemPackages = [ pkgs.qemu ];
}
