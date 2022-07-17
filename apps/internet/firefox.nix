{pkgs, ...}: {


  programs.firefox = {
    enable = true;
    extensions = with pkgs.nur.repos.rycee.firefox-addons; [
      ublock-origin
      vimium
      bitwarden
      buster-captcha-solver
    ];

    profiles.default = {
      id = 0;
      name = "eyad";
      isDefault = true;
    };
  };
}