# Games, streamed to any screen in the house. Wolf (Games on Whales) is a Moonlight
# server made for a machine with no monitor: every device that connects gets its own
# virtual screen, sound and controllers on the GPU, so there is no desktop session or
# dummy plug, and several rooms can play different things at once. What they play are
# container images Wolf fetches when first picked in its menu: Steam, RetroArch,
# ES-DE, Pegasus, Lutris, Heroic, Prism Launcher, Kodi, Firefox.
#
# Wolf is a container too, set up as its Podman quadlet has it
# (games-on-whales.github.io/wolf/stable/user/quickstart.html), and starts the apps
# through Podman's socket. That makes it root on this machine in all but name, and
# its images come by tag from ghcr.io rather than pinned in flake.lock like the rest.
#
# State is in /etc/wolf, where Wolf looks for it: pairings and settings in cfg/, and
# a home folder per profile and app in profile_data/ (Steam's library, saves, emulator
# settings). On home-server that is its own subvolume (hosts/home-server/disk.nix),
# so it outlives the root wipe and stays out of the hourly snapshots.
#
# Pairing a TV, ROMs and the rest: docs/homelab.md, "Games".
{
  config,
  lib,
  pkgs,
  homelab,
  ...
}:
let
  cfg = config.my.homelab;
  apps = cfg.apps;
  inherit (homelab) on;
  nvidia = config.hardware.nvidia.enabled;

  # Two files Wolf's quickstart has you download, at fixed revisions so a change
  # to them arrives as a commit here. Worth a look when Wolf's setup steps change.
  udevRules = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/games-on-whales/wolf/00e6c85e6d50d0616dbc040be762316e94159fcb/85-wolf.rules";
    hash = "sha256-UlZ698zh/ramYlk4uATg3vLB/ub3DbafNsNm9834FRw=";
  };
  driverDockerfile = pkgs.fetchurl {
    url = "https://raw.githubusercontent.com/games-on-whales/gow/9c486cf9f7e285fa041d9197e8d3a5275e51876f/images/nvidia-driver/Dockerfile";
    hash = "sha256-3vpJgDX70DKDIcCv4nQx0+OrQKpm3Z2Roq0avhGPRjw=";
  };

  # The device nodes the quickstart hands to Wolf on NVIDIA
  nvidiaDevices = [
    "/dev/nvidia-uvm"
    "/dev/nvidia-uvm-tools"
    "/dev/nvidia-caps/nvidia-cap1"
    "/dev/nvidia-caps/nvidia-cap2"
    "/dev/nvidiactl"
    "/dev/nvidia0"
    "/dev/nvidia-modeset"
  ];

  # The apps are ordinary images with no NVIDIA libraries in them. Wolf mounts a
  # volume holding the libraries into each one, and they must be the exact version
  # of the kernel module that is loaded. The quickstart builds that volume by hand
  # and says to rebuild it after every driver update; here it is rebuilt whenever
  # the loaded driver's version differs from the one the volume was built for, so
  # a nightly upgrade that brings a new driver needs nothing done after the reboot.
  driverVolume = pkgs.writeShellApplication {
    name = "wolf-nvidia-driver";
    runtimeInputs = [
      config.virtualisation.podman.package
      pkgs.nvidia-modprobe
      pkgs.coreutils
      pkgs.gnused
    ];
    text = ''
      # The driver's udev rules make most device nodes as its modules load; the
      # two capability nodes are only made when asked for.
      nvidia-modprobe -f /proc/driver/nvidia/capabilities/mig/config || true
      nvidia-modprobe -f /proc/driver/nvidia/capabilities/mig/monitor || true
      for node in ${toString nvidiaDevices}; do
        if [[ ! -e $node ]]; then
          echo "$node is missing, and Wolf cannot start without it" >&2
          exit 1
        fi
      done

      version=$(</sys/module/nvidia/version)
      built=$(podman volume inspect nvidia-driver-vol --format '{{ index .Labels "nvidia-version" }}' 2>/dev/null || true)
      if [[ $built == "$version" ]]; then
        exit 0
      fi
      echo "Building nvidia-driver-vol for driver $version (it held: ''${built:-nothing})"

      context=$(mktemp -d)
      trap 'rm -rf "$context"' EXIT
      # Podman won't guess which registry a bare `ubuntu` is from when nobody is
      # there to ask
      sed 's|^FROM ubuntu:|FROM docker.io/library/ubuntu:|' ${driverDockerfile} > "$context/Dockerfile"
      # Downloads Ubuntu and NVIDIA's installer; tried for half an hour, in case the
      # network isn't up yet after the reboot that brought the new driver
      for attempt in $(seq 30); do
        podman build --tag gow/nvidia-driver:latest --build-arg NV_VERSION="$version" "$context" && break
        if (( attempt == 30 )); then
          exit 1
        fi
        sleep 60
      done

      podman volume rm --force nvidia-driver-vol 2>/dev/null || true
      podman volume create --label nvidia-version="$version" nvidia-driver-vol
      # Podman copies the image's /usr/nvidia into the volume when a container
      # mounting it starts. The image holds nothing that can run, so the start
      # itself is allowed to fail; what counts is what the volume holds after.
      container=$(podman create --mount type=volume,source=nvidia-driver-vol,destination=/usr/nvidia gow/nvidia-driver:latest sh)
      podman start "$container" || true
      podman rm --force "$container"
      if [[ ! -d $(podman volume inspect nvidia-driver-vol --format '{{ .Mountpoint }}')/lib ]]; then
        podman volume rm --force nvidia-driver-vol
        echo "nvidia-driver-vol came out empty" >&2
        exit 1
      fi
    '';
  };
in
{
  options.my.homelab.gaming = {
    version = lib.mkOption {
      type = lib.types.str;
      default = "v2026.11";
      description = "Wolf's release, as its image tag.";
    };
    renderNode = lib.mkOption {
      type = lib.types.str;
      default = "/dev/dri/renderD128";
      description = ''
        The GPU Wolf renders and encodes on. With a second one in the machine (the
        CPU's own, say) the card may be renderD129:
        `ls -l /sys/class/drm/renderD*/device/driver` says which is which.
      '';
    };
    zeroCopy = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Hand frames from the game to the encoder without copying them. Faster, but
        on NVIDIA it has broken the other rooms' streams when one ends (wolf#265,
        wolf#501), so it stays off while several rooms play at once.
      '';
    };
    memoryLimit = lib.mkOption {
      type = lib.types.str;
      default = "4g";
      description = "The most memory Wolf itself may use (not the games).";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        # No tile: there is nothing to open in a browser but the pairing page.
        # Gatus still checks it, and with a domain the pairing page is at
        # https://wolf.<domain>/pin/
        my.homelab.apps.wolf = {
          port = 47989;
          title = "Wolf";
          description = "Games, streamed to Moonlight";
          group = "Games";
          health = "/serverinfo";
          dashboard = false;
        };
      }

      (lib.mkIf (on "wolf") {
        virtualisation.podman = {
          enable = true;
          # Images an update has replaced
          autoPrune.enable = true;
        };

        virtualisation.oci-containers = {
          backend = "podman";
          containers.wolf = {
            # A fixed release, bumped here on purpose: `stable` moves every month, and
            # one of its moves broke NVIDIA (wolf#243). Releases:
            # github.com/games-on-whales/wolf/releases
            image = "ghcr.io/games-on-whales/wolf:${cfg.gaming.version}";
            hostname = "wolf";
            networks = [ "host" ];
            environment = {
              WOLF_STOP_CONTAINER_ON_EXIT = "TRUE";
              WOLF_RENDER_NODE = cfg.gaming.renderNode;
              WOLF_USE_ZERO_COPY = if cfg.gaming.zeroCopy then "TRUE" else "FALSE";
            }
            // lib.optionalAttrs nvidia { NVIDIA_DRIVER_VOLUME_NAME = "nvidia-driver-vol"; };
            volumes = [
              "/etc/wolf:/etc/wolf"
              "/run/podman/podman.sock:/var/run/docker.sock:ro"
              "/dev:/dev:rw"
              "/run/udev:/run/udev:rw"
            ]
            ++ lib.optional nvidia "nvidia-driver-vol:/usr/nvidia";
            devices = [
              "/dev/dri"
              "/dev/uinput"
              "/dev/uhid"
            ]
            ++ lib.optionals nvidia nvidiaDevices;
            extraOptions = [
              "--ipc=host"
              # Input devices (major 13): the virtual controllers, mice and keyboards
              "--device-cgroup-rule=c 13:* rmw"
              # Wolf without zero-copy has leaked memory until the OOM killer came
              # (wolf#518); this keeps a leak to Wolf instead of Plex and the rest.
              # The games run in their own containers, outside this limit.
              "--memory=${cfg.gaming.memoryLimit}"
            ];
          };
        };

        systemd.services.podman-wolf = {
          requires = [ "podman.socket" ] ++ lib.optional nvidia "wolf-nvidia-driver.service";
          after = [ "podman.socket" ] ++ lib.optional nvidia "wolf-nvidia-driver.service";
          # Never write pairings and saves into a root that the next boot wipes
          unitConfig.RequiresMountsFor = "/etc/wolf";
          # Only once restarting has stopped helping
          onFailure = [ "notify-failure@%n.service" ];
          serviceConfig.RestartSec = 5;
          # Five failed starts within 5 minutes and it stops trying, which is what
          # tells ntfy; the default window is 10 seconds, which restarts every 5
          # seconds never fill, so a crash loop would go on unreported
          startLimitIntervalSec = 300;
          startLimitBurst = 5;
        };

        # Wolf encodes on the CPU when it can't load NVIDIA's encoder, which NixOS
        # users have hit (wolf#370), and says so only in its log. That would pin the
        # CPU Plex and everything else share, so it goes to ntfy.
        systemd.services.wolf-encoder-watch = lib.mkIf (nvidia && on "ntfy") {
          description = "Tell ntfy when Wolf falls back to encoding on the CPU";
          wantedBy = [ "podman-wolf.service" ];
          after = [ "podman-wolf.service" ];
          partOf = [ "podman-wolf.service" ];
          path = [
            config.systemd.package
            pkgs.gnugrep
            pkgs.curl
          ];
          script = ''
            journalctl -fu podman-wolf -n 0 -o cat |
              grep --line-buffered -i 'software .*encoder detected' |
              while read -r line; do
                curl -fsS -H "Title: Wolf is encoding on the CPU" -H "Tags: warning" \
                  --data-binary "$line" http://127.0.0.1:${toString apps.ntfy.port}/homelab || true
              done
          '';
          serviceConfig.Restart = "always";
        };

        systemd.services.wolf-nvidia-driver = lib.mkIf nvidia {
          description = "NVIDIA libraries for Wolf's apps, matching the loaded driver";
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];
          onFailure = [ "notify-failure@%n.service" ];
          serviceConfig = {
            Type = "oneshot";
            ExecStart = lib.getExe driverVolume;
          };
        };

        # Virtual gamepads are made through uinput, the DualSense through uhid.
        # Wolf's rules give it both, and keep the pads it makes off this machine's
        # own seat.
        services.udev.packages = [
          (pkgs.runCommand "wolf-udev-rules" { } ''
            install -Dm444 ${udevRules} $out/lib/udev/rules.d/85-wolf.rules
          '')
        ];
        boot.kernelModules = [
          "uinput"
          "uhid"
        ]
        # With no display the driver's modules aren't loaded at boot, and Wolf's
        # virtual screens need nvidia_drm, with modesetting
        ++ lib.optionals nvidia [
          "nvidia"
          "nvidia_modeset"
          "nvidia_uvm"
          "nvidia_drm"
        ];
        hardware.nvidia.modesetting.enable = lib.mkIf nvidia true;

        # Moonlight comes straight to Wolf, not through Caddy: pairing and the
        # stream's setup over TCP, then control, video and sound over UDP. mDNS is
        # how Moonlight finds the server without an address being typed.
        networking.firewall = {
          allowedTCPPorts = [
            47984
            47989
            48010
          ];
          allowedUDPPorts = [
            5353
            47999
            48100
            48200
          ];
        };

        systemd.tmpfiles.settings.homelab-gaming = {
          "/etc/wolf".d = {
            mode = "0755";
          };
          # One folder per system (snes, psx, ...), mounted into the emulators
          "/data/roms".d = {
            mode = "2775";
            user = "root";
            group = "media";
          };
        };

        # Saves, settings and pairings are backed up with the rest. The games Steam
        # installed aren't: they are large, and Steam fetches them again.
        my.homelab.backup = {
          extraPaths = [ "/etc/wolf" ];
          # Steam's games, wherever an image keeps them (~/.steam/debian-installation
          # on the Ubuntu-based image, ~/.local/share/Steam elsewhere)
          extraExcludes = map (dir: "/etc/wolf/**/steamapps/${dir}") [
            "common"
            "shadercache"
            "downloading"
            "temp"
          ];
        };
      })
    ]
  );
}
