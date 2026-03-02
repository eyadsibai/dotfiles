{ config, lib, pkgs, ... }:
{
  users.users.${config._module.args.username}.home = "/Users/${config._module.args.username}";
  networking.hostName = config._module.args.hostname;
}
