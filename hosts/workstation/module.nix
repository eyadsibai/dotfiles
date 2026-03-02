{ config, lib, pkgs, ... }:
{
  networking.hostName = config._module.args.hostname;
}
