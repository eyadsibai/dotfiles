# sops-nix: secrets live encrypted in ../../secrets/*.yaml (recipients in ../../.sops.yaml)
# and are decrypted at activation with this machine's SSH host key.
# Edit a secrets file with: just secret <name>
{
  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
}
