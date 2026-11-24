# Dell XPS 14 (2026), Omarchy on Arch: the laptop I carry. Home Manager only.
{ config, repoDir, ... }:
{
  my.files = [ "host-vector" ];

  # hyprmoncfg's monitor profiles, one per place this laptop gets plugged in. The folder
  # is linked whole, not file by file like the packages above: saving a profile in its
  # panel writes new files, and a link per file would leave those outside the repo.
  home.file.".config/hyprmoncfg/profiles".source =
    config.lib.file.mkOutOfStoreSymlink "${repoDir}/files/hyprmoncfg/.config/hyprmoncfg/profiles";

  # My own machines get this laptop's 1Password agent, named because `ForwardAgent yes`
  # would forward gnome-keyring's instead (where they're reached: modules/home/home-lan.nix)
  programs.ssh.settings = {
    "Host cachy".ForwardAgent = "~/.1password/agent.sock";
    "Host desktop".ForwardAgent = "~/.1password/agent.sock";
  };
  home.stateVersion = "26.05";
}
