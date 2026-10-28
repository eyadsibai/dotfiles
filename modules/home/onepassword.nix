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
  useremail,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  signingKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpovYakzNvqZRJKiE7H43QJ1Y1zJt3ixf+tvzDBNXJe";
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

  # Sign commits with the same key, held in 1Password (the "id_rsa" item, an ed25519 key)
  programs.git = {
    signing = {
      format = "ssh";
      key = signingKey;
      signByDefault = true;
      signer =
        if isDarwin then
          "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
          "${pkgs._1password-gui}/bin/op-ssh-sign";
    };
    # Lets `git log --show-signature` verify our own commits
    settings.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
  };
  xdg.configFile."git/allowed_signers".text = "${useremail} ${signingKey}\n";

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
