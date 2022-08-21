{ ... }: {
  services.samba = {
    enable = true;
    shares = {
      share = {
        "path" = "/home/eyad";
        "guest ok" = "no";
        "read only" = "no";
      };
    };
    openFirewall = true;
  };
}
