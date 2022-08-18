{ pkgs, ... }:
{
  programs.rbw = {
    enable = true;
    settings = {
      email = "eyad.alsibai@gmail.com";
      lock_timeout = 172800;
      pinentry = "tty";
    };
  };
}
