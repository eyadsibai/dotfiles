# My machines at home reach each other over the LAN and fall back to the tailnet, under
# the one name: `ssh cachy` is the same command on the sofa with Tailscale off and from
# anywhere else with it on.
{ lib, hostname, ... }:
let
  # The LAN addresses are what the router hands out today and have to stay reserved
  # there; if one moves, that machine is simply reached over the tailnet again. The
  # tailnet side is an address too, because cachy doesn't take the tailnet's DNS.
  # desktop (Windows) isn't built from this repo and is only ever connected to.
  machines = {
    vector = {
      lan = "192.168.8.194";
      tailnet = "100.110.54.93";
    };
    cachy = {
      lan = "192.168.8.204";
      tailnet = "100.123.22.98";
    };
    spark = {
      lan = "192.168.8.205";
      tailnet = "100.79.48.125";
    };
    workstation = {
      lan = "192.168.8.206";
      tailnet = "100.115.116.117";
    };
    desktop = {
      lan = "192.168.8.116";
      tailnet = "100.112.148.45";
      user = "eyada";
    };
  };
in
{
  programs.ssh.settings = lib.concatMapAttrs (name: machine: {
    # Asked first, and before `Host` because the first HostName wins. It answers at
    # once on the LAN and gives up after a second anywhere else; an address rather
    # than <name>.local, which takes 10 s to fail to resolve away from home.
    "Match originalhost ${name} exec \"nc -z -w1 ${machine.lan} 22 2>/dev/null\"" =
      lib.hm.dag.entryBefore [ "Host ${name}" ]
        { HostName = machine.lan; };
    "Host ${name}" = {
      HostName = machine.tailnet;
      # one known_hosts entry, whichever address it was reached at
      HostKeyAlias = name;
    }
    // lib.optionalAttrs (machine ? user) { User = machine.user; };
  }) (removeAttrs machines [ hostname ]);
}
