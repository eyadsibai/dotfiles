{ pkgs
, config
, ...
}:
{

  # programs.himalaya =
  #   {
  #     enable = true;
  #   };

  # programs.notmuch.enable = true;
  # services.lieer.enable = true;

  accounts.email.accounts = {
    "work" = {
      address = "${config.secrets.email.work.address}";
      primary = true; # needs to be rmeoved later
      # himalaya = {

      #   enable = true;
      #   # settings = { default = true; };
      # };

      imap = {
        host = "${config.secrets.email.work.host}";
        tls.enable = true;
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
