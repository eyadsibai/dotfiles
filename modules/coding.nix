{ pkgs, ... }:
{
  services.envfs.enable = true;

  environment.systemPackages = with pkgs; [
    nixd
    nil
    gnumake
    jetbrains.jdk
    jetbrains.idea-ultimate
    devbox
    git
  ];

}
