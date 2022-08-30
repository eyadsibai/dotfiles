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
      trusted-users = [ "root" "@wheel" ];
      sandbox = true;
    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };
}
