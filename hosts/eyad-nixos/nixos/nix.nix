{ inputs
, config
, pkgs
, lib
, username
, ...
}: {
  nix = {
    settings = {
      trusted-users = [ "root" "@wheel" ];
      sandbox = true;

    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };
}
