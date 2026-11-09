# Secure Boot through lanzaboote: the boot chain is signed with this machine's own keys,
# so a TPM-sealed disk key (systemd-cryptenroll) only unseals for this exact boot path.
# Off until the keys exist; enabling it first leaves an unbootable system. Steps, as root:
#   1. sbctl create-keys                      (keys in /var/lib/sbctl)
#   2. my.secureBoot.enable = true; switch; `sbctl verify` lists everything signed
#   3. firmware: Secure Boot to setup mode;  sbctl enroll-keys --microsoft;  reboot
#   4. firmware: Secure Boot on;  `bootctl status` says "Secure Boot: enabled (user)"
#   5. re-enroll the TPM with PCR 7 (docs/home-server.md)
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [ inputs.lanzaboote.nixosModules.lanzaboote ];

  options.my.secureBoot.enable = lib.mkEnableOption "Secure Boot with lanzaboote (keys created first)";

  config = lib.mkIf config.my.secureBoot.enable {
    boot.loader.systemd-boot.enable = lib.mkForce false;
    boot.lanzaboote = {
      enable = true;
      pkiBundle = "/var/lib/sbctl";
    };
    environment.systemPackages = [ pkgs.sbctl ];
  };
}
