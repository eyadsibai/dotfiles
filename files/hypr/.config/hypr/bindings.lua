-- Shared personal keybinding overrides across Arch/Omarchy hosts.
-- Host-specific bindings live in files/host-<name>/.config/hypr/bindings-local.lua.
--
-- See current bindings and descriptions:
--   omarchy menu keybindings --print

-- Meetings (omarchy-meetings): popup to record, and the latest meeting
o.bind("SUPER + ALT + M", "Meetings", "omarchy-shell meetings popup")
o.bind("SUPER + CTRL + M", "Latest meeting", os.getenv("HOME") .. "/.local/bin/meetings view last")

-- Play or open the copied link: videos in mpv, images and PDFs in their viewer
-- (linkhandler, from the newsboat module)
o.bind("SUPER + ALT + V", "Open copied link", "linkhandler")
-- …or pick what to do with it: mpv, loop, the TV, download, browser, subscribe
o.bind("SUPER + ALT + SHIFT + V", "Open copied link with…", "openwith")

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end

-- Per-machine bindings, loaded last so host overrides win.
require("default.hypr.require_optional").module("hypr.bindings-local")
