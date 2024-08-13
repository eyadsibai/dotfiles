{ pkgs, ... }: {
  home.packages = with pkgs; [
    # discord using discocss instead
    signal-desktop
    skypeforlinux
    slack
    # slack-term
    zoom-us
    # element-desktop
    # tdesktop
    # teams
    # whatsapp-for-linux install whatsie through flatpak instead
    distrobox
    # gitter
    # cawbird
    # haxor-news
    # rainbowstream
    caprine-bin
    # latest-caprine
    # wire-desktop
    kotatogram-desktop
    # gurk-rs
    # vk-messenger
    # matrix messaging client
    # jitsi-meet-electron
    # open source video calls and chat
    tuir
    tiptop
    # weechat
  ];
  # programs.hexchat = { enable = true; };
  # programs.nheko.enable = true;
}
