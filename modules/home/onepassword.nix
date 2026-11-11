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
  isArch,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) isDarwin isLinux;
  signingKey = import ../common/signing-key.nix;
  home = config.home.homeDirectory;
  agentSocket =
    if isDarwin then
      "${home}/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    else
      "${home}/.1password/agent.sock";

  # Kept at a fixed path: an option name (the Match line) can't refer to the store
  useLocalAgent = ".ssh/use-local-1password-agent";
in
{
  programs.ssh = {
    settings."Match host * exec ~/${useLocalAgent}".IdentityAgent = ''"${agentSocket}"'';
    # `ssh -A` forwards $SSH_AUTH_SOCK, which is launchd's empty agent on a Mac and
    # gnome-keyring's on Omarchy, never 1Password's; name the socket so logging in to
    # the workstation forwards it. Its own key below stays unforwarded, for unattended jobs.
    settings."Host workstation workstation-ts" = {
      ForwardAgent = ''"${agentSocket}"'';
    };
  };
  home.file.${useLocalAgent} = {
    executable = true;
    text = ''
      #!/bin/sh
      [ -z "$SSH_CONNECTION" ] || [ -z "$SSH_AUTH_SOCK" ]
    '';
  };

  # API keys as 1Password references rather than values: the variable holds the
  # op:// path, and only a command run as `op run -- <command>` (or `opr <command>`)
  # sees the secret itself, so it never sits in a file or in every shell's env.
  # Add one per key: "op://<vault>/<item>/<field>", as 1Password's "Copy Secret
  # Reference" gives it.
  home.sessionVariables = {
    # OPENAI_API_KEY = "op://Private/OpenAI/credential";
  };
  home.shellAliases.opr = "op run --";

  # Commits aren't signed: signing through 1Password kept failing when its approval
  # prompt couldn't reach the app. Older commits were signed with this key (the "id_rsa"
  # item, an ed25519 key), and this lets `git log --show-signature` still verify them.
  programs.git.settings.gpg.ssh.allowedSignersFile = "${config.xdg.configHome}/git/allowed_signers";
  xdg.configFile."git/allowed_signers".text = "${useremail} ${signingKey}\n";

  # Start the app hidden at login so the agent is always there (a login item on macOS).
  # Not on Arch: pacman's 1Password adds its own entry when Settings → General →
  # "Start at login" is on (autostart/com.onepassword.OnePassword.desktop), and with
  # both, two copies ran.
  xdg.configFile."autostart/1password.desktop" = lib.mkIf (isLinux && !isArch) {
    text = ''
      [Desktop Entry]
      Type=Application
      Name=1Password
      Exec=1password --silent
    '';
  };
}
