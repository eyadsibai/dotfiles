# LDAP tools

{ pkgs ? import <nixpkgs> { }, ... }:

{
  environment.systemPackages = with pkgs; [
    adenum
    ldapmonitor
    ldapdomaindump
    ldeep
  ];
}
