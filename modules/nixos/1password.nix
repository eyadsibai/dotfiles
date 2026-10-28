# 1Password desktop app + CLI (`op`). System level because the app needs a
# polkit policy (system-auth unlock) and the CLI needs a setgid wrapper to talk to it.
{ username, ... }:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    polkitPolicyOwners = [ username ];
  };
}
