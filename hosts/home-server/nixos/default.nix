{ inputs
, config
, pkgs
, lib
, username
, hostname
, ...
}: {
  services.sonarr = {
    #6767

    enable = true;
    user = "sonarr";
    group = "sonarr";
    openFirewall = true;
    # dataDir = "/config/services/sonarr/data";
  };

  services.bazarr = {
    #6767

    enable = true;
    user = "bazarr";
    group = "bazarr";
    openFirewall = true;
  };
  services.lidarr = {
    enable = true;
    user = "lidarr";
    group = "lidarr";
    openFirewall = true;
    # dataDir = "/var/lib/lidarr";
  };

  services.radarr = {
    #7878
    enable = true;
    user = "radarr";
    group = "radarr";
    openFirewall = true;
    # dataDir = "/config/services/radarr/data";
  };
  services.prowlarr = {
    #9696
    enable = true;
    openFirewall = true;
  };
  services.deluge = {
    #8112
    enable = true;
    web.enable = true;
    user = "root";
    group = "users";
    openFirewall = true;
    web.openFirewall = true;
  };

  services.adguardhome.enable = true;

  services.minidlna.enable = true;
}
