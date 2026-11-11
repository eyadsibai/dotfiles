# 1Password desktop app + CLI (`op`). System level because the app needs a
# polkit policy (system-auth unlock) and the CLI needs a setgid wrapper to talk to it.
# Not on servers: there is nobody to unlock it.
{
  config,
  lib,
  username,
  ...
}:
lib.mkIf (!config.my.server) {
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };
}
