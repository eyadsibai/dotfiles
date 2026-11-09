-- Learn how to configure Hyprland: https://wiki.hypr.land/Configuring/Start/

-- Omarchy's bootstrap keeps path setup out of this user config.
dofile((os.getenv("OMARCHY_PATH") or "/usr/share/omarchy") .. "/default/hypr/bootstrap.lua")

-- Disable all Omarchy default bindings. Add your own in hypr/bindings.lua.
-- omarchy_default_bindings = false
--
-- Or disable only bindings for Omarchy's preinstalled apps/web apps while
-- keeping core window-manager bindings:
-- omarchy_preinstalled_bindings = false

-- Load Omarchy defaults.
require("default.hypr.omarchy")

-- Put your personal overrides in these files. They're loaded after Omarchy's
-- defaults so package updates can improve the defaults without rewriting your
-- ~/.config/hypr files.
require("hypr.monitors")
require("hypr.input")
require("hypr.bindings")
require("hypr.looknfeel")
require("hypr.autostart")

-- Toggle config flags dynamically.
require("default.hypr.toggles")

-- Add any other personal Hyprland configuration below.
-- o.window("qemu", { workspace = "5" })

-- Bitwarden runs natively on Wayland here (see ~/.local/share/applications/bitwarden.desktop),
-- where its app id is the lowercase "bitwarden". Omarchy's shipped rule in
-- default/hypr/apps/bitwarden.lua only matches the XWayland class "Bitwarden",
-- so mirror it for the Wayland id to get the same floating-window treatment.
o.window("^(bitwarden)$", { no_screen_share = true, tag = "+floating-window" })

-- Live TV: ~/.local/bin/tv runs mpv under the "mpv-tv" app id (see the [tv]
-- profile in ~/.config/mpv/tv/tv.conf). A plain "mpv" class gets Omarchy's
-- floating-window treatment and the default 0.985/0.96 window opacity; the TV
-- window should tile like any app and never dim the picture.
o.window("^(mpv-tv|mpv-tv-pip)$", { tag = "-default-opacity", opacity = "1 1" })
-- The corner TV (tv --pip): a small floating picture pinned top-right on every workspace.
o.window("^(mpv-tv-pip)$", {
  float = true,
  pin = true,
  size = { 480, 270 },
  move = { "(monitor_w-480-24)", "(52)" },
})

-- Omarchy Meeting Recorder: centered floating window.
o.window("^com\\.jankeesvw\\.OmarchyMeetingRecorder$", { float = true, size = { 480, 700 }, center = true })

-- The caster (eyad.media's CastWindow, a window of the Omarchy shell): centered and floating.
o.window({ class = "^org\\.quickshell$", title = "^Cast$" }, { float = true, size = { 1000, 660 }, center = true })
-- The TV remote: floating, pinned so it follows across workspaces, bottom-right.
-- Move it with Super+drag or its header; Super+W closes it.
o.window({ class = "^org\\.quickshell$", title = "^TV remote$" }, {
  float = true,
  pin = true,
  size = { 460, 780 },
  -- the size, not window_w/h: those are still the window's own size when this runs
  move = { "(monitor_w-460-40)", "(monitor_h-780-40)" },
})

-- Zoom desktop app (class "Zoom" on native Wayland, "zoom" under XWayland).
-- Float its popups/dialogs; keep the main and meeting windows tiled.
o.window({ class = "^(Zoom|zoom)$", title = "negative:^(Zoom Workplace|Zoom Meeting|Meeting|Zoom)$" }, { float = true })
-- No transparency on video (Omarchy's default rule only matches "zoom").
o.window("^Zoom$", { tag = "-default-opacity", opacity = "1 1" })
