{ username, ... }: {
  services.samba = {
    enable = false;
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
