{ user, ... }: {
  services.samba = {
    enable = true;
    shares = {
      share = {
        "path" = "/home/${user}";
        "guest ok" = "no";
        "read only" = "no";
      };
    };
    openFirewall = true;
  };
}
