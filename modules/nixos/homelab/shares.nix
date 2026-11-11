# Network shares (Samba), for what reaches the server as files rather than through an
# app, the way Unraid's shares did:
#   data         all of /data: drop films or music in, tidy the library by hand
#   timemachine  the Macs' Time Machine backups, found by the Macs on their own
#   scans        a scanner or phone saves here and Paperless takes it in
#
# Only from home and the tailnet, signed in as me. The password is samba/password in
# secrets/home-server.yaml, so the shares wait for my.homelab.secrets.enable.
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
let
  cfg = config.my.homelab;
  sh = cfg.shares;
  paperless = cfg.apps.paperless.enable;

  # New files stay in the media group and writable by its apps, as on /data
  mediaShare = {
    "valid users" = username;
    "read only" = "no";
    "force group" = "media";
    "create mask" = "0664";
    "directory mask" = "2775";
  };
in
{
  options.my.homelab.shares = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = cfg.secrets.enable;
      defaultText = lib.literalExpression "config.my.homelab.secrets.enable";
      description = "Samba shares of /data, Time Machine and the scanner's inbox.";
    };
    timeMachineSize = lib.mkOption {
      type = lib.types.str;
      default = "1T";
      description = "How much Time Machine may fill for each Mac before deleting old backups.";
    };
  };

  config = lib.mkIf (cfg.enable && sh.enable) {
    assertions = [
      {
        assertion = cfg.secrets.enable;
        message = "my.homelab.shares needs my.homelab.secrets.enable for samba/password.";
      }
    ];

    sops.secrets."samba/password" = { };

    services.samba = {
      enable = true;
      openFirewall = true;
      settings = {
        global = {
          "server string" = config.networking.hostName;
          # Home and the tailnet, over IPv4 and IPv6 (Macs often connect over the
          # latter); "ALL" also covers IPv6, which 0.0.0.0/0 doesn't
          "hosts allow" = lib.concatStringsSep " " (
            cfg.lanSubnets
            ++ [
              "100.64.0.0/10"
              "fe80::/10"
              "fd00::/8"
              "fd7a:115c:a1e0::/48"
              "127.0.0.1"
              "::1"
            ]
          );
          "hosts deny" = "ALL";
          security = "user";
          "map to guest" = "never";
          "invalid users" = [ "root" ];
          # What macOS needs for its metadata and Time Machine, on every share
          "vfs objects" = "catia fruit streams_xattr";
          "fruit:metadata" = "stream";
          "fruit:model" = "MacSamba";
          "fruit:posix_rename" = "yes";
          "fruit:delete_empty_adfiles" = "yes";
        };
        data = mediaShare // {
          path = "/data";
        };
        timemachine = {
          path = "/data/timemachine";
          "valid users" = username;
          "read only" = "no";
          "fruit:time machine" = "yes";
          "fruit:time machine max size" = sh.timeMachineSize;
        };
      }
      // lib.optionalAttrs paperless {
        scans = {
          path = config.services.paperless.consumptionDir;
          "valid users" = username;
          "read only" = "no";
          "create mask" = "0666";
        };
      };
    };
    # Paperless runs as its own user and has to read and then delete what I save
    services.paperless.consumptionDirIsPublic = lib.mkIf paperless true;

    # Samba's own password database, set from the secret before it starts
    systemd.services.samba-password = {
      description = "Set ${username}'s Samba password";
      wantedBy = [ "samba-smbd.service" ];
      before = [ "samba-smbd.service" ];
      serviceConfig.Type = "oneshot";
      script = ''
        pass=$(<${config.sops.secrets."samba/password".path})
        printf '%s\n%s\n' "$pass" "$pass" | ${lib.getExe' config.services.samba.package "smbpasswd"} -s -a ${username}
      '';
    };

    systemd.tmpfiles.settings.homelab-shares."/data/timemachine".d = {
      mode = "0700";
      user = username;
      group = "users";
    };

    # NetBIOS name service and winbind: for old Windows networks and domains; nothing
    # here uses them
    services.samba.nmbd.enable = false;
    services.samba.winbindd.enable = false;

    # The Macs find the shares, Time Machine's among them, over Bonjour; Windows
    # over WS-Discovery. nixpkgs' Samba isn't built with Avahi, so it can't announce
    # them itself: these service files do, including the record that tells macOS
    # the timemachine share takes backups.
    services.avahi = {
      enable = true;
      openFirewall = true;
      settings.publish = {
        disable-publishing = false;
        disable-user-service-publishing = false;
        publish-addresses = true;
      };
      extraServiceFiles.samba = ''
        <?xml version="1.0" standalone='no'?>
        <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
        <service-group>
          <name replace-wildcards="yes">%h</name>
          <service>
            <type>_smb._tcp</type>
            <port>445</port>
          </service>
          <service>
            <type>_device-info._tcp</type>
            <port>9</port>
            <txt-record>model=MacSamba</txt-record>
          </service>
          <service>
            <type>_adisk._tcp</type>
            <port>9</port>
            <txt-record>sys=waMa=0,adVF=0x100</txt-record>
            <txt-record>dk0=adVN=timemachine,adVF=0x82</txt-record>
          </service>
        </service-group>
      '';
    };
    # Printers would be found through Avahi too and shared on; nothing prints here
    services.printing.browsed.enable = false;
    services.samba-wsdd = {
      enable = true;
      openFirewall = true;
    };
  };
}
