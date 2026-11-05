-- Keep only your personal keybinding overrides here. Add new bindings or
-- unbind defaults before replacing them.

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

-- Change an existing binding by unbinding it first, then binding the key again.
-- This example changes SUPER+SPACE from the launcher to the Omarchy root menu.
-- hl.unbind("SUPER + SPACE")
-- o.bind("SUPER + SPACE", "Omarchy menu", "omarchy-menu toggle root")

-- Disable a default binding without replacing it.
-- hl.unbind("SUPER + SHIFT + B")

-- Bring workspace N to whichever monitor is focused, swapping it with the
-- workspace sitting there. Omarchy's SUPER+SHIFT+ALT+<arrow> pushes the current
-- workspace to a neighbouring monitor; this is the pull in the other direction,
-- which is what you need over VNC: on the headless "remote" output,
-- SUPER+SHIFT+CTRL+3 drags workspace 3 across without having to see the Dell.
-- Digits are bound by keycode (code:10 = 1 ... code:19 = 0), same as Omarchy.
for workspace = 1, 10 do
  o.bind(
    "SUPER + SHIFT + CTRL + code:" .. tostring(workspace + 9),
    "Bring workspace " .. workspace .. " to this monitor",
    hl.dsp.focus({ workspace = tostring(workspace), on_current_monitor = true })
  )
end

-- Swap the two monitors' workspaces outright. swap_monitors needs both outputs
-- named, so read them at press time instead of hardcoding "remote" (that output
-- only exists while remote-display.service is up).
o.bind("SUPER + SHIFT + CTRL + TAB", "Swap workspaces between monitors", function()
  local monitors = hl.get_monitors()
  if #monitors ~= 2 then
    return
  end
  hl.dispatch(hl.dsp.workspace.swap_monitors({ monitor1 = monitors[1].name, monitor2 = monitors[2].name }))
end)

-- Logitech MX Keys examples:
o.bind("SUPER + SHIFT + S", nil, "omarchy-capture-screenshot")
o.bind("SUPER + PERIOD", nil, "omarchy-shell shell toggle omarchy.emojis")

-- Spoken conversation with Claude: hold F10, speak, release, hear the answer.
-- SHIFT+F10 forgets the conversation so the next question starts fresh.
local voice_agent = os.getenv("HOME") .. "/.local/bin/voice-agent"
o.bind("F10", "Ask Claude by voice (push-to-talk)", voice_agent .. " start")
o.bind("F10", "Send voice question to Claude", voice_agent .. " stop", { release = true })
o.bind("SHIFT + F10", "New voice conversation with Claude", voice_agent .. " reset")



o.bind("SUPER + F1", nil, "ddcutil setvcp 60 0x1b --noverify") --  USB-C
o.bind("SUPER + F2", nil, "ddcutil setvcp 60 0x11 --noverify") --  HDMI-1 (this machine)
o.bind("SUPER + F3", nil, "ddcutil setvcp 60 0x12 --noverify") --  HDMI-2

-- >>> eyad.akiflow >>>
-- Akiflow's desktop apps use Ctrl+E for the command bar, Ctrl+Y for the tray
-- window and Ctrl+J to join the next meeting. The same letters on SUPER+ALT
-- keep that muscle memory without taking Ctrl+E/Y/J from applications.
o.bind("SUPER + ALT + E", "Akiflow quick add", "omarchy-shell -q akiflow add")
o.bind("SUPER + ALT + Y", "Akiflow today", "omarchy-shell -q akiflow agenda")
o.bind("SUPER + ALT + J", "Join current meeting", "omarchy-shell -q akiflow join")

-- Quick add prefilled with the clipboard, like pasting into Akiflow's
-- command bar. Titles with a URL get it attached as a link.
o.bind("SUPER + ALT + C", "Akiflow capture clipboard",
  "sh -c 'omarchy-shell -q akiflow capture \"$(wl-paste -n -t text 2>/dev/null | head -c 1000)\"'")
-- <<< eyad.akiflow <<<

-- >>> eyad.water >>>
-- Ask what you drank and log it in OmaWater (the usual is first, so Enter
-- repeats it). SUPER+SHIFT+W is Omawrite, so this rides the SUPER+ALT row
-- with the Akiflow keys.
o.bind("SUPER + ALT + W", "Log a drink", "omarchy-shell -q eyad.water ask")
-- <<< eyad.water <<<

-- BEGIN OmaPilot managed hotkeys
-- Added at the user request from OmaPilot settings. Edit these bindings freely.
hl.unbind("SUPER + A")
o.bind("SUPER + A", "Talk to OmaPilot",
  "omarchy-shell -q io.github.spencerbull.omapilot voiceToggle")
hl.unbind("SUPER + SHIFT + A")
o.bind("SUPER + SHIFT + A", "New OmaPilot voice chat",
  "omarchy-shell -q io.github.spencerbull.omapilot newVoiceChat")
hl.unbind("SUPER + ALT + X")
o.bind("SUPER + ALT + X", "Cancel OmaPilot voice mode",
  "omarchy-shell -q io.github.spencerbull.omapilot voiceCancel")
hl.unbind("SUPER + ALT + N")
o.bind("SUPER + ALT + N", "New OmaPilot chat",
  "omarchy-shell -q io.github.spencerbull.omapilot newChat")
hl.unbind("SUPER + ALT + H")
o.bind("SUPER + ALT + H", "Continue OmaPilot chat in Herdr",
  "omarchy-shell -q io.github.spencerbull.omapilot continueInHerdr")
-- END OmaPilot managed hotkeys

-- Dictation keys from before Alt + Space and Right Alt became the defaults.
-- Remove these lines to give the keys back to applications.
if o.dictation_installed and o.dictation_installed() then
  o.bind("SUPER + CTRL + X", "Toggle dictation", "omarchy-dictation toggle")
  o.bind_hold("F9", "Start dictation (push-to-talk)", "omarchy-dictation start", "Stop dictation (push-to-talk)", "omarchy-dictation stop")
end
