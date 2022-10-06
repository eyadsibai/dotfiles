{ lib, pkgs, ... }:

rec {
  default = pkgs.callPackage ../shell.nix { };
  python = import ./python { inherit pkgs; };
  cc = import ./cc { inherit pkgs; };
  bluetooth = import ./penetration/bluetooth.nix { inherit pkgs; };
  code = import ./penetration/code.nix { inherit pkgs; };
  container = import ./penetration/container.nix { inherit pkgs; };
  dns = import ./penetration/dns.nix { inherit pkgs; };
  forensics = import ./penetration/forensics.nix { inherit pkgs; };
  fuzzers = import ./penetration/fuzzers.nix { inherit pkgs; };
  generic = import ./penetration/generic.nix { inherit pkgs; };
  hardware = import ./penetration/hardware.nix { inherit pkgs; };
  host = import ./penetration/host.nix { inherit pkgs; };
  information-gathering = import ./penetration/information-gathering.nix { inherit pkgs; };
  kubernetes = import ./penetration/kubernetes.nix { inherit pkgs; };
  ldap = import ./penetration/ldap.nix { inherit pkgs; };
  load-testing = import ./penetration/load-testing.nix { inherit pkgs; };
  malware = import ./penetration/malware.nix { inherit pkgs; };
  misc = import ./penetration/misc.nix { inherit pkgs; };
  mobile = import ./penetration/mobile.nix { inherit pkgs; };
  network = import ./penetration/network.nix { inherit pkgs; };
  packet-generators = import ./penetration/packet-generators.nix { inherit pkgs; };
  password = import ./penetration/password.nix { inherit pkgs; };
  port-scanners = import ./penetration/port-scanners.nix { inherit pkgs; };
  proxies = import ./penetration/proxies.nix { inherit pkgs; };
  services = import ./penetration/services.nix { inherit pkgs; };
  smartcards = import ./penetration/smartcards.nix { inherit pkgs; };
  terminals = import ./penetration/terminals.nix { inherit pkgs; };
  traffic = import ./penetration/traffic.nix { inherit pkgs; };
  tunneling = import ./penetration/tunneling.nix { inherit pkgs; };
  voip = import ./penetration/voip.nix { inherit pkgs; };
  web = import ./penetration/web.nix { inherit pkgs; };
  windows = import ./penetration/windows.nix { inherit pkgs; };
  wireless = import ./penetration/wireless.nix { inherit pkgs; };
  penetration-full = lib.mergeEnvs { inherit pkgs; } [
    bluetooth
    code
    container
    dns
    forensics
    fuzzers
    generic
    hardware
    host
    information-gathering
    kubernetes
    ldap
    load-testing
    malware
    misc
    mobile
    network
    packet-generators
    password
    port-scanners
    proxies
    services
    smartcards
    terminals
    traffic
    tunneling
    voip
    web
    windows
    wireless
  ];
}
