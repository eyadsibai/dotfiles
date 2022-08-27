{ inputs
, config
, pkgs
, lib
, ...
}:
{

  environment.systemPackages = with pkgs; [ cachix ];
  nix = {
    settings = {
      trusted-users = [ "root" "eyad" ];
      sandbox = true;
    };
    daemonIOSchedClass = "idle";
    daemonCPUSchedPolicy = "idle";
  };
}
