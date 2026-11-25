-- Host-specific Hyprland bindings for vector (loaded by hypr/bindings.lua).

-- X: Super+Shift+X opens/focuses the X web app (single window, no duplicates)
o.rebind("SUPER + SHIFT + X", "X", "omarchy-launch-or-focus-webapp chrome-x.com https://x.com/")

-- Strata instead of Nautilus for Omarchy's file-manager shortcuts. The markers
-- are the Strata installer's: it replaces what's between them on a reinstall.
-- strata-installer: file-manager start
o.rebind("SUPER + SHIFT + F", "File manager", { launch = "/usr/bin/strata" })
o.rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)",
  "uwsm-app -- /usr/bin/strata \"$(omarchy-cmd-terminal-cwd)\"")
-- strata-installer: file-manager end

-- TV remote (eyad.media): touchpad, buttons and typing for the living-room TV
o.bind("SUPER + SHIFT + R", "TV remote", "omarchy-shell eyad.media remote")
