{ pkgs, ... }: {
  programs.rbw = {
    enable = true;
    settings = {
      email = builtins.concatStringsSep "@" [ (builtins.concatStringsSep "." [ "eyad" "alsibai" ]) "gmail.com" ];
      lock_timeout = 172800;
      pinentry = pkgs.pinentry-tty;
    };
  };
}
