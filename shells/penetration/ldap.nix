# LDAP tools
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    adenum
    ldapmonitor
    ldapdomaindump
    ldeep
  ];
  shellHook = "";
}
