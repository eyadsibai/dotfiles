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

      keep-outputs = true;
      keep-derivations = true;
    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";


  };
}
