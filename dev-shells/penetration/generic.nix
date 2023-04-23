# Generic tools (terminals, packers, clients, etc.)
{ pkgs ? import <nixpkgs> { }, ... }:
with pkgs;
mkShell
{
  buildInputs = [
    chrony
    clamav
    curl
    dorkscout
    flashrom
    htop
    httpie
    hurl
    inetutils
    inxi
    ioccheck
    iproute
    iproute2
    iw
    lynx
    macchanger
    nano
    parted
    pwgen
    spyre
    utillinux
    wget
    xh
    # Terminal helpers
    eternal-terminal
    mosh
    shellz
    # Common client for various protocols
    cifs-utils
    freerdp
    net-snmp
    nfs-utils
    ntp
    openssh
    openvpn
    samba
    step-cli
    # tightvnc
    wireguard-go
    wireguard-tools
    xrdp
    # Network design helpers
    ipcalc
    netmask
    # Terminal multiplexer
    tmux
    # Archive tools

  ];
  shellHook = "";
}
