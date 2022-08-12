{ pkgs
, ...
}:
{
  home.packages =
    with pkgs;
    [
      discord
      signal-desktop
      skypeforlinux
      slack
      slack-term
      zoom-us
      element-desktop
      tdesktop
      teams
      whatsapp-for-linux
      gitter
      cawbird
      haxor-news
      rainbowstream
      caprine-bin
      wire-desktop
      kotatogram-desktop
      gurk-rs
      vk-messenger
      nheko
      # matrix messaging client
      jitsi-meet-electron
      # open source video calls and chat
      tuir
      tiptop
      weechat
    ];
  programs.hexchat = { enable = true; };
}
