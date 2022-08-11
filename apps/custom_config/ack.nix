{ config
, pkgs
, ...
}: {
  home.file.".ackrc".source =
    config.lib.file.mkOutOfStoreSymlink ./files/.ackrc;
}
