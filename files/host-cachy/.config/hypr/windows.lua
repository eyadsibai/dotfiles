-- Window rules for this machine only. hyprland.lua loads this last, so a rule
-- here wins over Omarchy's defaults and over the shared rules.

-- This desktop is mostly used through gliff, which reads the screen the way a
-- screen share does. Omarchy hides 1Password from every capture
-- (default/hypr/apps/1password.lua), so over gliff its windows were simply not
-- there. Showing them means they also appear in screenshots, recordings and
-- shared screens made on this machine.
o.window("^(1[pP]assword|com\\.onepassword\\.OnePassword)$", { no_screen_share = false })
