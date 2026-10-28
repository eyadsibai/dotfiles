# 1Password as the SSH agent: private keys live in the vault and SSH asks the app
# to sign. Turn it on once in the app: Settings → Developer → "Use the SSH agent".
# Key files still in ~/.ssh keep working as a fallback until they are removed.
#
# Only for sessions at the machine itself: logged in over SSH, the local app's
# approval prompt would appear on a screen nobody is looking at, so SSH then uses
# the agent forwarded from the machine you came from (`ssh -A`, i.e. its 1Password).
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  home = config.home.homeDirectory;
  agentSocket =
    if isDarwin then
      "${home}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${home}/.1password/agent.sock";
in
{
  programs.ssh = {
    enable = true;
    enableDefaultConfig = false;
    # True when $SSH_CONNECTION is empty; %%%% is a literal %% to ssh, and %% keeps a
    # single word so `test` stays quiet when it is set
    settings."Match host * exec \"test -z \${SSH_CONNECTION%%%% *}\"".IdentityAgent =
      ''"${agentSocket}"'';
  };

  # Start the app hidden at login so the agent is always there (a login item on macOS)
  xdg.configFile."autostart/1password.desktop" = lib.mkIf isLinux {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=1Password
      Exec=1password --silent
    '';
  };
}
