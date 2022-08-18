{ pkgs
, secrets
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
      address = secrets.email.work.address;
      primary = true; # needs to be rmeoved later
      # himalaya = {

      #   enable = true;
      #   # settings = { default = true; };
      # };

      imap = {
        host = secrets.email.work.host;
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
