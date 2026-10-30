# Omarchy desktop (Hyprland, Quickshell bar/menus/lock, themes) through nixarchy,
# which packages the upstream Omarchy tree for NixOS. Started by greetd; with
# my.desktop.autoLogin the first session of each boot logs in by itself and locks
# straight away, so remote tools (Sunshine, gliff) have a session after a reboot.
{
  config,
  inputs,
  lib,
  pkgs,
  repoDir,
  username,
  ...
}:
let
  cfg = config.my.desktop;

  # Omarchy's tree, built against nixpkgs' Hyprland rather than the hyprwm flake
  # (which would otherwise be compiled locally, as its cache is not trusted here)
  omarchy = (pkgs.extend inputs.nixarchy.overlays.default).omarchy.override {
    inherit (pkgs) hyprland;
    inherit chromium;
  };

  # Omarchy's Chromium flags (config/chromium-flags.conf) with its bundled extensions
  # (copy URL, yt-dlp, WhatsApp). On Arch, Chromium's launcher reads that file and the
  # extensions sit in /usr/share/omarchy; nixpkgs' launcher reads no flags file, so
  # they are built in here, from the system profile's copy of the Omarchy tree.
  # Fixed in nixarchy after v4.5.0-rc2-1 (#1491): drop this and nativeHosts with
  # the next pin that includes it
  omarchyExtensions = "/run/current-system/sw/share/omarchy/default/chromium/extensions";
  chromium = pkgs.chromium.override {
    commandLineArgs = [
      "--password-store=gnome-libsecret"
      # One --enable-features only: Chromium keeps the last, so repeat the Wayland one
      # nixpkgs adds (NIXOS_OZONE_WL) instead of replacing it
      "--enable-features=WaylandWindowDecorations,TouchpadOverscrollHistoryNavigation"
      "--load-extension=${
        lib.concatMapStringsSep "," (e: "${omarchyExtensions}/${e}") [
          "copy-url"
          "yt-dlp"
          "whatsapp-slim"
        ]
      }"
      "--no-default-browser-check"
    ];
  };

  # Copy URL and yt-dlp talk to small host programs. Omarchy registers them once, by
  # store path, which the next update removes; re-register them at every activation
  # through the stable /run/current-system path instead
  nativeHosts = {
    "com.omarchy.copy_url" = "omarchy-chromium-copy-url-host";
    "com.omarchy.ytdlp" = "omarchy-chromium-ytdlp-host";
  };

  # nixarchy's session launcher, read from its wayland-sessions entry at login
  # so greetd always starts the current generation's build
  omarchySession = pkgs.writeShellScript "omarchy-session" ''
    exec $(${lib.getExe pkgs.gnused} -n 's/^Exec=//p' /run/current-system/sw/share/wayland-sessions/omarchy.desktop)
  '';
in
{
  imports = [ inputs.nixarchy.nixosModules.nixarchy ];

  options.my.desktop.autoLogin = lib.mkEnableOption "logging in automatically at boot, then locking the screen";

  config = {
    programs.nixarchy = {
      enable = true;
      user = username;
      package = omarchy;
      flake = repoDir;
      displayManager = false; # greetd below instead of SDDM
      bootSplash = "off";
      # Only cache.nixos.org and the caches in nix.nix are trusted; nixarchy's own
      # pieces are small and build locally
      binaryCaches = false;
      # Except the community CUDA cache (cache.nixos-cuda.org): cache.nixos.org has
      # no cudaSupport builds, and ollama-cuda alone is a huge compile. nixarchy adds
      # it only where hardware.nvidia is enabled, so the laptop and `just vm` skip it
      cudaCache = true;
      # Leave Claude Code's config, editors and command-not-found as Home Manager has them
      mcp = false;
      nixSkills = false;
      languageServer = false;
      commandNotFound = false;
    };

    # Hyprland from nixpkgs (on cache.nixos.org) instead of nixarchy's hyprwm input
    programs.hyprland.package = lib.mkForce pkgs.hyprland;
    programs.hyprland.portalPackage = lib.mkForce pkgs.xdg-desktop-portal-hyprland;

    # Unlock the login keyring with the password typed at the lock screen, as a
    # greeter login already does (greetd includes the login PAM stack). With
    # autologin there is no password at login, so the first unlock opens it. Omarchy
    # on Arch avoids the prompt with an unencrypted keyring instead. nixarchy
    # defaults to this after v4.5.0-rc2-1 (#1492); drop it with that pin.
    security.pam.services.omarchy-lock-password.enableGnomeKeyring = true;

    services.greetd = {
      enable = true;
      settings = {
        # A text greeter that offers the Omarchy session
        default_session.command = lib.concatStringsSep " " [
          (lib.getExe pkgs.tuigreet)
          "--time"
          "--remember"
          "--asterisks"
          "--cmd ${omarchySession}"
        ];
        # Once per boot, straight into the desktop; it locks itself immediately
        initial_session = lib.mkIf cfg.autoLogin {
          command = "${omarchySession}";
          user = username;
        };
      };
    };

    # A module function, for Home Manager's lib (lib.hm.dag)
    home-manager.users.${username} =
      { lib, ... }:
      {
        imports = [
          ../home/omarchy.nix
          ../home/desktop-apps.nix
          ../home/firefox.nix
        ];
        programs.nixarchy.package = omarchy;

        # omatheme's own activation step copies a changed ~/.config/starship.toml into
        # its runtime dir but doesn't re-render the prompt from it; that only happens
        # at login or on a theme change, so a switched prompt stayed stale until then
        home.activation.hyprchromaShell = lib.hm.dag.entryAfter [ "nixarchyThemeEngineShell" ] ''
          [[ -v DRY_RUN ]] || run ${config.programs.nixarchyThemeEngine.package}/bin/hyprchroma shell --quiet
        '';

        home.activation.omarchyChromiumHosts = lib.hm.dag.entryAfter [ "writeBoundary" ] (
          lib.concatStrings (
            lib.mapAttrsToList (name: host: ''
              run mkdir -p "$HOME/.config/chromium/NativeMessagingHosts"
              [[ -v DRY_RUN ]] || ${lib.getExe pkgs.gnused} 's|__HOST_PATH__|/run/current-system/sw/bin/${host}|' \
                ${omarchy}/share/omarchy/default/chromium/native-messaging-hosts/${name}.json \
                > "$HOME/.config/chromium/NativeMessagingHosts/${name}.json"
            '') nativeHosts
          )
        );

        # Lock the autologin session as soon as the shell can draw the lock screen.
        # Later logins went through the greeter and are left alone.
        xdg.configFile."omarchy/hooks/post-boot.d/10-lock-after-autologin" = lib.mkIf cfg.autoLogin {
          text = ''
            marker="/tmp/omarchy-autolock-$USER-$(cat /proc/sys/kernel/random/boot_id)"
            [[ -e $marker ]] && exit 0
            touch "$marker"
            for _ in $(seq 30); do
              omarchy-system-lock
              sleep 1
              omarchy-hyprland-session-locked && exit 0
            done
            echo "Could not lock the session after autologin" >&2
            exit 1
          '';
        };
      };
  };
}
