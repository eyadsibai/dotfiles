{ config, pkgs, ... }: {
  home.file.".ackrc".source =
    config.lib.file.mkOutOfStoreSymlink ./config_files/.ackrc;

}
