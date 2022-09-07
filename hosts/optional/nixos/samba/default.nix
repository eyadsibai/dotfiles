{ username, ... }: {
  services.samba = {
    enable = true;
    shares = {
      share = {
        "path" = "/home/${username}";
        "guest ok" = "no";
        "read only" = "no";
      };
    };
    openFirewall = true;
  };
}
