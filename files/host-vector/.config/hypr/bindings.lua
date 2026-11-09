-- Keep only your personal keybinding overrides here. Add new bindings with
-- o.bind or replace defaults with o.rebind.

-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- To disable every Omarchy default binding, set this in
-- ~/.config/hypr/hyprland.lua before require("default.hypr.omarchy"), then add
-- only the bindings you want below:
--   omarchy_default_bindings = false

-- To disable all preinstalled app/webapp bindings, set:
--   omarchy_preinstalled_bindings = false

-- Add a new binding.
-- o.bind("SUPER + SHIFT + R", "SSH", "alacritty -e ssh your-server")

-- Change an existing binding. o.rebind takes the same arguments as o.bind.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- o.rebind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Logitech MX Keys examples:
-- o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
-- o.bind("SUPER + H", nil, "voxtype record toggle")
-- o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- X: Super+Shift+X opens/focuses the X web app (single window, no duplicates)
o.rebind("SUPER + SHIFT + X", "X", "omarchy-launch-or-focus-webapp chrome-x.com https://x.com/")

-- Strata instead of Nautilus for Omarchy's file-manager shortcuts. The markers
-- are the Strata installer's: it replaces what's between them on a reinstall.
-- strata-installer: file-manager start
o.rebind("SUPER + SHIFT + F", "File manager", { launch = "/usr/bin/strata" })
o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)",
  "uwsm-app -- /usr/bin/strata \"$(omarchy-cmd-terminal-cwd)\"")
-- strata-installer: file-manager end

-- Meetings (omarchy-meetings): popup to record, and the latest meeting
o.bind("SUPER + ALT + M", "Meetings", "omarchy-shell meetings popup")
o.bind("SUPER + CTRL + M", "Latest meeting", "/home/eyad/.local/bin/meetings view last")

-- TV remote (eyad.media): touchpad, buttons and typing for the living-room TV
o.bind("SUPER + SHIFT + R", "TV remote", "omarchy-shell eyad.media remote")

-- Play or open the copied link: videos in mpv, images and PDFs in their viewer
-- (linkhandler, from the newsboat module)
o.bind("SUPER + ALT + V", "Open copied link", "linkhandler")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
