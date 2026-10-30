# 1Password as the SSH agent: private keys live in the vault and SSH asks the app
# to sign. Turn it on once in the app: Settings → Developer → "Use the SSH agent".
#
# Logged in over SSH, the local app's approval prompt would appear on a screen nobody
# is looking at, so a forwarded agent (`ssh -A`, i.e. your own 1Password) wins when
# there is one; without one, SSH falls back to this machine's app.
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
  # At the machine itself, or over SSH without a forwarded agent (then the local
  # app is the only key source left; its prompt shows on this machine's screen)
  opSshSign =
    if isDarwin then
      "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
    else
      "${pkgs._1password-gui}/bin/op-ssh-sign";
  # op-ssh-sign asks this machine's 1Password app, whose prompt shows on this
  # machine's screen. Over SSH with a forwarded agent, sign through that agent
  # instead, so the 1Password you're sitting at approves it
  signer = pkgs.writeShellScript "git-ssh-sign" ''
    if [ -n "$SSH_CONNECTION" ] && [ -n "$SSH_AUTH_SOCK" ]; then
      exec ${pkgs.openssh}/bin/ssh-keygen "$@"
    fi
    exec "${opSshSign}" "$@"
  '';

  # Kept at a fixed path: an option name (the Match line) can't refer to the store
  useLocalAgent = ".ssh/use-local-1password-agent";
in
{
  programs.ssh = {
    settings."Match host * exec ~/${useLocalAgent}".IdentityAgent = ''"${agentSocket}"'';
    # `ssh -A` forwards $SSH_AUTH_SOCK, which on a Mac is launchd's empty agent rather
    # than 1Password's; name the socket so logging in to the workstation forwards it
    settings."Host workstation" = lib.mkIf isDarwin { ForwardAgent = ''"${agentSocket}"''; };
  };
  home.file.${useLocalAgent} = {
    executable = true;
    text = ''
      #!/bin/sh
      [ -z "$SSH_CONNECTION" ] || [ -z "$SSH_AUTH_SOCK" ]
    '';
  };

  # Sign commits with the same key, held in 1Password (the "id_rsa" item, an ed25519 key)
  programs.git = {
    signing = {
      format = "ssh";
      key = signingKey;
      signByDefault = true;
      signer = "${signer}";
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
