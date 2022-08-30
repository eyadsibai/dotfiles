{ inputs
, config
, pkgs
, lib
, user
, ...
}:
{

  environment.systemPackages = with pkgs; [ cachix ];
  nix = {
    settings = {
      trusted-users = [ "root" ${user} ];
      sandbox = true;
    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };
}
