{ lib, config, username, ... }:
let homeConfig = config.home-manager.users.${username};
in

{
  home-manager.users.${username}.wayland.windowManager.hyprland.settings = {
    "$mod" = "SUPER";

    bind = [
      "$mod, 1, workspace, 1"
      "$mod, 2, workspace, 2"
      "$mod, 3, workspace, 3"
      "$mod, 4, workspace, 4"
      "$mod, 5, workspace, 5"
      "$mod, 6, workspace, 6"
      "$mod, 7, workspace, 7"
      "$mod, 8, workspace, 8"
      "$mod, 9, workspace, 9"
      "$mod, 0, workspace, 10"
      "$mod SHIFT, 1, movetoworkspace, 1"
      "$mod SHIFT, 2, movetoworkspace, 2"
      "$mod SHIFT, 3, movetoworkspace, 3"
      "$mod SHIFT, 4, movetoworkspace, 4"
      "$mod SHIFT, 5, movetoworkspace, 5"
      "$mod SHIFT, 6, movetoworkspace, 6"
      "$mod SHIFT, 7, movetoworkspace, 7"
      "$mod SHIFT, 8, movetoworkspace, 8"
      "$mod SHIFT, 9, movetoworkspace, 9"
      "$mod SHIFT, 0, movetoworkspace, 10"

      "$mod, H, focus, left"
      "$mod, J, focus, down"
      "$mod, K, focus, up"
      "$mod, L, focus, right"
      "$mod, Left, focus, left"
      "$mod, Down, focus, down"
      "$mod, Up, focus, up"
      "$mod, Right, focus, right"

      "$mod SHIFT, H, move, left"
      "$mod SHIFT, J, move, down"
      "$mod SHIFT, K, move, up"
      "$mod SHIFT, L, move, right"
      "$mod SHIFT, Left, move, left"
      "$mod SHIFT, Down, move, down"
      "$mod SHIFT, Up, move, up"
      "$mod SHIFT, Right, move, right"


      
      

      "$mod, Return, exec, ${homeConfig.home.preferredApps.terminal.cmd}"
      "$mod, D, exec, ${homeConfig.home.preferredApps.menu.drun-cmd}"
      "$mod Shift, D, exec, ${homeConfig.home.preferredApps.menu.window-cmd}"
      "$mod, N, exec, ${pkgs.networkmanager_dmenu}/bin/networkmanager_dmenu"
      "$mod, P, exec, ${homeConfig.home.preferredApps.menu.password-cmd}"
      "$mod Shift, X, exec, systemctl suspend"
      "Print, exec, ${pkgs.flameshot}/bin/flameshot gui"
      "$mod, B, exec, ${homeConfig.home.preferredApps.browser.cmd}"

      "$mod, F, fullscreen"
      "$mod SHIFT, Q, kill"


    ];
  };
}
