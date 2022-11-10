{ pkgs
, config
, ...
}: {
  # programs.himalaya =
  #   {
  #     enable = true;
  #   };

  # programs.notmuch.enable = true;
  # services.lieer.enable = true;

  programs.thunderbird = {
    enable = true;
    profiles."work" = {
      #   name = "work";
      isDefault = true;
    };
  };



  accounts.email.accounts = {
    "work" = {
      address = "${config.secrets.emails.work.address}";
      primary = true; # needs to be rmeoved later
      realName = "Eyad Sibai";
      # himalaya = {

      #   enable = true;
      #   # settings = { default = true; };
      # };

      imap = {
        host = "${config.secrets.emails.work.host}";
        tls.enable = true;
      };

      thunderbird = {
        enable = true;
        profiles = [ "work" ];
      };
    };
    # "personal-gmail" = {
    #   primary = true;
    #   maildir = "~/mail";
    #   realName = "Eyad Sibai";
    #   address = "eyad.alsibai@gmail.com";
    #   flavor = "gmail.com";
    #   lieer = {
    #     enable = true;
    #     sync = {
    #       enable = true;
    #       frequency = "*:0/5";
    #     };
    #   };
    #   notmuch = {
    #     enable = true;
    #   };

    # };
  };
}
