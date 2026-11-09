-- tv.lua — "TV mode" for mpv. Loaded only by the [tv] profile in tv.conf
-- (script=~~/tv/tv.lua), so none of this touches normal video playback.
--
-- What it adds on top of a plain playlist:
--   * Per-channel HTTP headers. mpv ignores the #EXTVLCOPT:http-referrer /
--     http-user-agent lines (and the http-referrer="…" EXTINF attributes) that
--     iptv-org playlists rely on; without them Rotana & co. never load. This
--     reads them from the .m3u and applies them per file in an on_load hook.
--   * Signed URLs (tv-resolve="…" EXTINF attribute): a fresh tokenized link is
--     fetched each time the channel opens or reconnects.
--   * Channel menus (uosc): ENTER or c files channels under tidy categories
--     (News, Movies, Kids & Family…) with Favorites and Recent on top; / lists
--     them all with the search open. Names drop "(1080p)"; "[Geo-blocked]" and
--     "[Not 24/7]" become tags. Falls back to mpv's built-in select.lua.
--   * Favorites (s, or Ctrl+S on a menu row) and the last channel (TAB).
--   * A channel banner (logo, number, name, category, language), and uosc's
--     colours, from the Omarchy theme; both follow a theme change while playing.
--   * $XDG_RUNTIME_DIR/tv/now.json for the Omarchy bar (`tv --bar`), and script
--     messages tv-menu / tv-next / tv-prev / tv-last / tv-star for `tv --ctl`.
--   * Remote-style channel numbers: type digits (0-9 / keypad), ENTER or a
--     short pause jumps to that channel.  r reloads the current channel.
--     PGUP/PGDN change channel, / or Shift+ENTER searches all channels,
--     -/+ change the volume and M mutes.
--   * Auto-reconnect when a live stream drops (EOF on a stream that should
--     never end), a few times per channel before stopping (r tries again).
--   * Dead-channel guard: a failing channel is skipped with an OSD note (after
--     one retry if tv-check last saw it alive), but a long run of failures
--     (network down) stops zapping instead of looping through the whole list.
--   * Remembers the last channel in ~/.local/state/tv/last so the `tv`
--     launcher can resume there.
--
-- Script options (script-opts/tv.conf or --script-opts=tv-<key>=<value>):
--   playlist=<path>            m3u to read metadata from (default: --playlist)
--   max_failures=8             consecutive load failures before zapping stops
--   reload_on_eof=yes          reconnect when a live stream ends
--   reload_max=3               reconnect attempts per channel per reload_window
--   reload_window=120          seconds
--   digit_timeout=1.5          seconds before a typed channel number is applied
--   osd_seconds=2.5            how long messages stay up
--   banner_seconds=4           how long the channel banner stays up
--   theme_file=~/.local/state/omarchy/current/theme/colors.toml   Omarchy's colours;
--                              without it, uosc keeps its own and the banner a neutral set
--   favorites_file, recent_file   ~/.local/state/tv/{favorites,recent}
--   runtime_dir=$XDG_RUNTIME_DIR/tv   now.json for the bar
--   logo_dir=~/.cache/tv/logos       channel logos (tvg-logo), converted for mpv
--   state_file=~/.local/state/tv/last
--   health_file=~/.local/state/tv/health.json   written by tv-check; channels it
--                              knows as good get one retry before being skipped,
--                              known-dead ones are skipped at once and muted in the menu
-- Both state defaults use $XDG_STATE_HOME/tv when XDG_STATE_HOME is nonempty.

local mp = require 'mp'
local msg = require 'mp.msg'
local utils = require 'mp.utils'

local state_home = os.getenv('XDG_STATE_HOME')
if not state_home or state_home == '' then state_home = '~/.local/state' end

local o = {
    playlist = '',
    max_failures = 8,
    reload_on_eof = true,
    reload_max = 3,
    reload_window = 120,
    digit_timeout = 1.5,
    osd_seconds = 2.5,
    banner_seconds = 4,
    theme_file = '~/.local/state/omarchy/current/theme/colors.toml',
    favorites_file = state_home .. '/tv/favorites',
    recent_file = state_home .. '/tv/recent',
    runtime_dir = (os.getenv('XDG_RUNTIME_DIR') or '/tmp') .. '/tv',
    logo_dir = '~/.cache/tv/logos',
    dump = '',   -- test hook (tests/parsers.sh): write parsed channels here and quit
    state_file = state_home .. '/tv/last',
    health_file = state_home .. '/tv/health.json',
}
require('mp.options').read_options(o, 'tv')

local function expand(path)
    if not path or path == '' then return nil end
    return mp.command_native({ 'expand-path', path })
end

local function osd(text, seconds)
    mp.osd_message(text, seconds or o.osd_seconds)
end

local function trim(s)
    return (s:gsub('^%s+', ''):gsub('%s+$', ''))
end

local function open_for_write(path)
    local f = io.open(path, 'w')
    if not f then
        -- First run: create the state dir (synchronously; 'run' is async) and retry.
        local dir = path:match('^(.*)/[^/]+$')
        if dir then
            mp.command_native({ name = 'subprocess', args = { 'mkdir', '-p', dir }, playback_only = false })
            f = io.open(path, 'w')
        end
    end
    return f
end

-- ---------------------------------------------------------------------------
-- Playlist metadata (group, headers) keyed by URL
-- ---------------------------------------------------------------------------

local meta = { by_url = {}, groups = {}, path = nil, mtime = nil }

local function playlist_path()
    local p = o.playlist ~= '' and o.playlist or mp.get_property('options/playlist')
    if not p or p == '' then
        p = mp.get_property('playlist/0/playlist-path')
    end
    return expand(p)
end

-- Name = text after the first comma outside a quoted attribute value. A plain
-- first-comma split (what mpv itself does) breaks on values that contain commas.
-- tv (awk) and tv-check (Python) use the same rule; tests/parsers.sh checks it.
local function extinf_title(line)
    local quoted = false
    for i = 1, #line do
        local ch = line:sub(i, i)
        if ch == '"' then
            quoted = not quoted
        elseif ch == ',' and not quoted then
            return trim(line:sub(i + 1))
        end
    end
    return ''
end

local function parse_m3u(path)
    local f = io.open(path, 'r')
    if not f then return nil end
    local by_url, groups, seen = {}, {}, {}
    local pending = nil
    for raw in f:lines() do
        local line = raw:gsub('\r$', '')
        if line:match('^#EXTINF') then
            pending = {
                title = extinf_title(line),
                group = line:match('group%-title="([^"]*)"') or '',
                referrer = line:match('http%-referrer="([^"]*)"'),
                user_agent = line:match('http%-user%-agent="([^"]*)"'),
                origin = line:match('http%-origin="([^"]*)"'),
                resolve = line:match('tv%-resolve="([^"]*)"'),
                logo = line:match('tvg%-logo="([^"]*)"'),
            }
        elseif line:match('^#EXTVLCOPT:') then
            if pending then
                local k, v = line:match('^#EXTVLCOPT:([%w%-]+)=(.*)$')
                v = v and trim(v) or nil
                if k == 'http-referrer' then pending.referrer = v
                elseif k == 'http-user-agent' then pending.user_agent = v
                elseif k == 'http-origin' then pending.origin = v
                end
            end
        elseif line:match('^#') or line:match('^%s*$') then
            -- comment / blank: keep pending so managed-block markers don't break it
        else
            local url = trim(line)
            local e = pending or { title = url, group = '' }
            e.url = url
            if e.title == '' then e.title = url end
            -- iptv-org uses "A;B" for multi-category channels; file them under the first
            e.group = trim(e.group:match('^([^;]*)') or '')
            if e.group == '' then e.group = 'Other' end
            if not by_url[url] then
                by_url[url] = e
                if not seen[e.group] then
                    seen[e.group] = true
                    groups[#groups + 1] = e.group
                end
            end
            pending = nil
        end
    end
    f:close()
    return { by_url = by_url, groups = groups }
end

local function refresh_meta()
    local path = playlist_path()
    if not path then return end
    local info = utils.file_info(path)
    local mtime = info and info.mtime or nil
    if meta.path == path and meta.mtime == mtime and next(meta.by_url) then return end
    local parsed = parse_m3u(path)
    if not parsed then
        msg.warn('could not read playlist metadata from ' .. path)
        return
    end
    meta.by_url, meta.groups, meta.path, meta.mtime = parsed.by_url, parsed.groups, path, mtime
    local n = 0
    for _ in pairs(meta.by_url) do n = n + 1 end
    msg.info(string.format('loaded metadata for %d channels in %d groups from %s', n, #meta.groups, path))
end

-- Per-URL failure streaks from tv-check (optional).
local health = { by_url = {}, mtime = nil }

local function refresh_health()
    local path = expand(o.health_file)
    if not path then return end
    local info = utils.file_info(path)
    if not info then return end
    if health.mtime == info.mtime then return end
    local f = io.open(path, 'r')
    if not f then return end
    local data = utils.parse_json(f:read('*a'))
    f:close()
    if type(data) == 'table' then
        health.by_url, health.mtime = data, info.mtime
    end
end

-- true = last probe fine, false = last probe failed, nil = unknown
local function known_state(url)
    local rec = url and health.by_url[url]
    if type(rec) ~= 'table' or rec.fails == nil then return nil end
    return tonumber(rec.fails) == 0
end

local function entry_for(url)
    if not url then return nil end
    return meta.by_url[url]
end

-- ---------------------------------------------------------------------------
-- Tidy names and categories. This playlist's group-titles read "<source> - <kind>"
-- (Shahid - Drama, IPTV - News, English - Movies, Extra - Kids): channels are
-- filed under the kind, folded into a few categories, and the source becomes a
-- language. The m3u keeps its own groups; tv and tv-check still use those.
-- ---------------------------------------------------------------------------

local CATEGORIES = {   -- menu order; the first whose words match the kind wins
    { 'News', { 'news', 'business' } },
    { 'General', { 'general', 'entertainment', 'shows', 'comedy', 'cooking', 'food' } },
    { 'Series & Drama', { 'series', 'drama' } },
    { 'Movies', { 'movie', 'classic', 'cinema' } },
    { 'Kids & Family', { 'kids', 'animation', 'family' } },
    { 'Sports', { 'sport', 'outdoor' } },
    { 'Documentary', { 'documentary', 'culture', 'education' } },
    { 'Music & Radio', { 'music', 'radio' } },
    { 'Religious', { 'religious' } },
}
local OTHER = 'Other'
local LANGUAGES = { english = 'English', extra = 'World' }   -- by source; the rest are Arabic

local function category_of(group)
    local kind = (group:match('^.- %- (.+)$') or group):lower()
    for _, c in ipairs(CATEGORIES) do
        for _, word in ipairs(c[2]) do
            if kind:find(word, 1, true) then return c[1] end
        end
    end
    return OTHER
end

local function language_of(group)
    local source = group:match('^(.-) %- .+$')
    if not source then return nil end
    return LANGUAGES[source:lower()] or 'Arabic'
end

-- "Rotana Cinema KSA (1080p) [Geo-blocked]" -> "Rotana Cinema KSA", { "geo-blocked" }
local function tidy_title(title)
    local tags = {}
    for tag in title:gmatch('%[([^%]]+)%]') do tags[#tags + 1] = tag:lower() end
    local name = title:gsub('%s*%[[^%]]*%]', ''):gsub('%s*%(%d+[pi]%)', '')
    name = trim(name)
    return name ~= '' and name or title, tags
end

-- Everything the menu, banner and bar show about a channel.
local function channel_info(url, fallback_title)
    local e = entry_for(url)
    local title = (e and e.title and e.title ~= '') and e.title or fallback_title or url or '?'
    local name, tags = tidy_title(title)
    local group = e and e.group or OTHER
    return {
        url = url, name = name, tags = tags, logo = e and e.logo,
        category = category_of(group), language = language_of(group),
    }
end

local function utf8_cut(s, n)
    if #s <= n then return s end
    while n > 0 and s:byte(n + 1) and s:byte(n + 1) >= 0x80 and s:byte(n + 1) < 0xC0 do n = n - 1 end
    return s:sub(1, n) .. '…'
end

-- ---------------------------------------------------------------------------
-- Favorites and recent channels, one URL per line in the state dir
-- ---------------------------------------------------------------------------

local favorites, recent = {}, {}   -- url -> true; urls, newest first

local function read_lines(path)
    local lines = {}
    local f = path and io.open(path, 'r')
    if not f then return lines end
    for raw in f:lines() do
        local line = trim(raw)
        if line ~= '' then lines[#lines + 1] = line end
    end
    f:close()
    return lines
end

local function write_lines(path, lines)
    local f = path and open_for_write(path)
    if not f then return end
    for _, line in ipairs(lines) do f:write(line, '\n') end
    f:close()
end

local function load_lists()
    favorites = {}
    for _, url in ipairs(read_lines(expand(o.favorites_file))) do favorites[url] = true end
    recent = read_lines(expand(o.recent_file))
end

local function save_favorites()
    local list = {}
    for url in pairs(favorites) do list[#list + 1] = url end
    table.sort(list)
    write_lines(expand(o.favorites_file), list)
end

local function push_recent(url)
    if not url then return end
    local list = { url }
    for _, u in ipairs(recent) do
        if u ~= url and #list < 12 then list[#list + 1] = u end
    end
    recent = list
    write_lines(expand(o.recent_file), recent)
end

-- ---------------------------------------------------------------------------
-- Signed URLs: tv-resolve="<m3u url>" fetches that playlist on every load and
-- plays its line whose URL (minus the ?query) matches the channel's, so short-
-- lived tokens are fresh on each zap and reconnect. The playlist keeps the bare
-- URL, so numbering, health and last-channel stay keyed on it.
-- ---------------------------------------------------------------------------

local function resolve_url(e)
    local r = mp.command_native({
        name = 'subprocess', playback_only = false, capture_stdout = true, capture_stderr = true,
        args = { 'curl', '-fsSL', '--max-time', '10', '-A', 'Mozilla/5.0', e.resolve },
    })
    if not r or r.status ~= 0 then
        msg.warn('could not fetch ' .. e.resolve .. ': ' .. trim((r and r.stderr) or 'curl failed'))
        return nil
    end
    local base = e.url:match('^[^?]*')
    for line in r.stdout:gmatch('[^\r\n]+') do
        line = trim(line)
        if not line:match('^#') and line:match('^[^?]*') == base then return line end
    end
    msg.warn(e.resolve .. ' has no link for ' .. base)
    return nil
end

-- ---------------------------------------------------------------------------
-- Per-channel HTTP headers (the #EXTVLCOPT fix)
-- ---------------------------------------------------------------------------

mp.add_hook('on_load', 10, function()
    refresh_meta()
    refresh_health()
    local url = mp.get_property('stream-open-filename') or mp.get_property('path')
    local e = entry_for(url)
    if not e then return end
    if e.resolve and e.resolve ~= '' then
        local signed = resolve_url(e)
        if signed then
            mp.set_property('stream-open-filename', signed)
            msg.verbose('resolved ' .. (e.title or url))
        end
    end
    if e.referrer and e.referrer ~= '' then
        mp.set_property('file-local-options/referrer', e.referrer)
    end
    if e.user_agent and e.user_agent ~= '' then
        mp.set_property('file-local-options/user-agent', e.user_agent)
    end
    if e.origin and e.origin ~= '' then
        mp.set_property_native('file-local-options/http-header-fields', { 'Origin: ' .. e.origin })
    end
    if e.referrer or e.user_agent or e.origin then
        msg.verbose('applied headers for ' .. (e.title or url))
    end
    -- mpv splits EXTINF at the first comma, so a comma inside an attribute value
    -- leaves it with a mangled title; prefer the properly parsed one.
    local pos = mp.get_property_number('playlist-pos') or -1
    local mpv_title = pos >= 0 and mp.get_property(string.format('playlist/%d/title', pos)) or nil
    if e.title and e.title ~= '' and mpv_title ~= e.title then
        mp.set_property('file-local-options/force-media-title', e.title)
    end
end)

-- ---------------------------------------------------------------------------
-- Channel banner + last-channel memory
-- ---------------------------------------------------------------------------

local current = { pos = nil, title = nil, url = nil }
local consecutive_failures = 0

local function playlist_title(pos)
    local url = mp.get_property(string.format('playlist/%d/filename', pos))
    local e = entry_for(url)
    if e and e.title and e.title ~= '' then return e.title end
    local t = mp.get_property(string.format('playlist/%d/title', pos))
    if t and t ~= '' then return t end
    return url or '?'
end

local function remember_channel(url)
    local path = expand(o.state_file)
    if not path or not url then return end
    local f = open_for_write(path)
    if f then
        f:write(url, '\n')
        f:close()
    end
end

-- ---------------------------------------------------------------------------
-- Omarchy theme: uosc's colours and the banner's, re-read every few seconds so a
-- theme change shows while TV plays. Without the file uosc keeps its own colours.
-- ---------------------------------------------------------------------------

local theme = {
    background = '141414', surface = '242424', foreground = 'e6e6e6',
    muted = '9a9a9a', accent = '69c5ff', red = 'ff616e', green = 'a5e075', yellow = 'e5c07b',
}
local theme_text = nil

local function apply_uosc_colors()
    local t = theme
    mp.commandv('change-list', 'script-opts', 'append', 'uosc-color=' .. table.concat({
        'foreground=' .. t.accent, 'foreground_text=' .. t.background,
        'background=' .. t.background, 'background_text=' .. t.foreground,
        'curtain=' .. t.background, 'window_border=' .. t.accent,
        'success=' .. t.green, 'error=' .. t.red, 'match=' .. t.yellow,
    }, ','))
end

-- true when the theme changed
local function load_theme()
    local path = expand(o.theme_file)
    local f = path and io.open(path, 'r')
    if not f then return false end
    local text = f:read('*a')
    f:close()
    if text == theme_text then return false end
    theme_text = text
    local v = {}
    for key, hex in text:gmatch('([%w_]+)%s*=%s*"#?(%x%x%x%x%x%x)"') do v[key] = hex:lower() end
    theme.background = v.background or theme.background
    theme.surface = v.lighter_background or v.selection or theme.surface
    theme.foreground = v.foreground or theme.foreground
    theme.muted = v.muted or v.dark_foreground or theme.muted
    theme.accent = v.accent or theme.accent
    theme.red = v.red or theme.red
    theme.green = v.green or theme.green
    theme.yellow = v.yellow or theme.yellow
    apply_uosc_colors()
    return true
end

-- ---------------------------------------------------------------------------
-- Channel banner: bottom-left, logo (tvg-logo, else initials), number and name,
-- category · language · position, LIVE, and the channel TAB goes back to.
-- ---------------------------------------------------------------------------

local banner = mp.create_osd_overlay('ass-events')
local banner_shown, banner_timer = false, nil
local LOGO_ID, LOGO_PX = 61, 128
local logo_failed, logo_fetching = {}, {}

local function ass_color(hex) return '&H' .. hex:sub(5, 6) .. hex:sub(3, 4) .. hex:sub(1, 2) .. '&' end
local function ass_text(s) return (s:gsub('\\', '\\\\'):gsub('{', '\\{'):gsub('}', '\\}'):gsub('\n', ' ')) end

local function ass_rect(x, y, w, h, hex, alpha)
    return string.format('{\\an7\\pos(%d,%d)\\bord0\\shad0\\1c%s\\1a&H%s&\\p1}m 0 0 l %d 0 %d %d 0 %d{\\p0}',
        x, y, ass_color(hex), alpha or '00', w, w, h, h)
end

local function ass_line(x, y, align, size, hex, bold, body)
    return string.format('{\\an%d\\pos(%d,%d)\\bord0\\shad0\\fn%s\\fs%d\\b%d\\1c%s}%s', align, x, y,
        mp.get_property('osd-font') or 'sans-serif', size, bold and 1 or 0, ass_color(hex), body)
end

local function hash(s)
    local h = 5381
    for i = 1, #s do h = (h * 33 + s:byte(i)) % 4294967296 end
    return string.format('%08x', h)
end

local function initials(name)
    local out = ''
    for word in name:gmatch('%S+') do
        local c = word:match('^[%w]')
        if c then out = out .. c:upper() end
        if #out == 2 then break end
    end
    return out ~= '' and out or name:sub(1, 1)
end

local function hide_banner()
    banner_shown = false
    banner:remove()
    mp.commandv('overlay-remove', tostring(LOGO_ID))
end

-- The logo as raw premultiplied BGRA (what overlay-add takes), converted once and
-- cached; ffmpeg can't read some (SVG), and those keep the initials.
local function logo_file(url) return expand(o.logo_dir) .. '/' .. hash(url) .. '.bgra' end

local draw_banner

local function fetch_logo(url, file)
    if logo_fetching[file] or logo_failed[file] then return end
    logo_fetching[file] = true
    local script = 'mkdir -p "$(dirname "$2")" && curl -fsSL --max-time 8 -A Mozilla/5.0 "$1" -o "$2.src" && '
        .. 'ffmpeg -nostdin -loglevel error -y -i "$2.src" -vf "format=rgba,scale=' .. LOGO_PX .. ':' .. LOGO_PX
        .. ':force_original_aspect_ratio=decrease,pad=' .. LOGO_PX .. ':' .. LOGO_PX
        .. ':(ow-iw)/2:(oh-ih)/2:color=black@0,premultiply=inplace=1,format=bgra" -frames:v 1 -f rawvideo "$2.tmp" '
        .. '&& mv "$2.tmp" "$2"; rm -f "$2.src" "$2.tmp"'
    mp.command_native_async({ name = 'subprocess', playback_only = false, capture_stderr = true,
        args = { 'sh', '-c', script, 'sh', url, file } }, function()
        logo_fetching[file] = nil
        if utils.file_info(file) then
            if banner_shown then draw_banner() end
        else
            logo_failed[file] = true
        end
    end)
end

draw_banner = function()
    local url = current.url
    local pos = mp.get_property_number('playlist-pos') or -1
    local count = mp.get_property_number('playlist-count') or 0
    local dims = mp.get_property_native('osd-dimensions')
    if not url or pos < 0 or not dims or (dims.w or 0) == 0 or (dims.h or 0) == 0 then return end
    local c = channel_info(url, current.title)
    local t = theme
    -- Laid out on a 720-high canvas, so it scales with the window.
    local H = 720
    local W = math.floor(H * dims.w / dims.h)
    banner.res_x, banner.res_y = W, H
    local bw, bh, pad, tile = math.min(560, W - 48), 96, 16, 64
    local x, y = 24, H - 24 - bh
    local tx = x + pad + tile + 16
    local meta = { c.category }
    if c.language then meta[#meta + 1] = c.language end
    for _, tag in ipairs(c.tags) do meta[#meta + 1] = tag end
    meta[#meta + 1] = string.format('%d of %d', pos + 1, count)
    local name = ass_text(utf8_cut(c.name, 30))
    if favorites[url] then name = name .. '{\\1c' .. ass_color(t.accent) .. '}  ★' end
    local parts = {
        ass_rect(x, y, bw, bh, t.background, '14'),
        ass_rect(x, y, bw, 2, t.accent),
        ass_rect(x + pad, y + pad, tile, tile, t.surface),
        ass_line(tx, y + 14, 7, 30, t.accent, true, tostring(pos + 1)
            .. '{\\fs22\\1c' .. ass_color(t.foreground) .. '}   ' .. name),
        ass_line(tx, y + 60, 7, 14, t.muted, false, ass_text(table.concat(meta, '  ·  '))),
        ass_rect(x + bw - pad - 52, y + pad, 52, 22, t.red),
        ass_line(x + bw - pad - 26, y + pad + 11, 5, 13, t.background, true, 'LIVE'),
    }
    local last = recent[2]
    if last and last ~= url then
        parts[#parts + 1] = ass_line(x + bw - pad, y + bh - 14, 3, 13, t.muted, false,
            ass_text('TAB ⇄ ' .. utf8_cut(channel_info(last).name, 18)))
    end
    -- the logo, or initials until (or unless) there is one
    local file = c.logo and c.logo ~= '' and logo_file(c.logo)
    local have_logo = file and utils.file_info(file)
    if have_logo then
        local scale = dims.h / H
        local d = math.floor(tile * scale)
        mp.commandv('overlay-add', tostring(LOGO_ID), tostring(math.floor((x + pad) * scale)),
            tostring(math.floor((y + pad) * scale)), file, '0', 'bgra', tostring(LOGO_PX), tostring(LOGO_PX),
            tostring(LOGO_PX * 4), tostring(d), tostring(d))
    else
        mp.commandv('overlay-remove', tostring(LOGO_ID))
        parts[#parts + 1] = ass_line(x + pad + tile / 2, y + pad + tile / 2, 5, 22, t.foreground, true,
            ass_text(initials(c.name)))
        if file then fetch_logo(c.logo, file) end
    end
    banner.data = table.concat(parts, '\n')
    banner:update()
    banner_shown = true
end

local function show_banner()
    if banner_timer then banner_timer:kill() end
    draw_banner()
    banner_timer = mp.add_timeout(o.banner_seconds, hide_banner)
end

mp.observe_property('osd-dimensions', 'native', function()
    if banner_shown then draw_banner() end
end)

-- The bar's view of TV: written on every change, removed when mpv quits.
local function now_file() return expand(o.runtime_dir) .. '/now.json' end

local function write_now()
    local url = current.url
    local pos = mp.get_property_number('playlist-pos') or -1
    if not url or pos < 0 then return end
    local c = channel_info(url, current.title)
    local where = c.category .. (c.language and (' · ' .. c.language) or '')
    local f = open_for_write(now_file())
    if not f then return end
    f:write(utils.format_json({
        pid = mp.get_property_number('pid'), number = pos + 1, name = c.name,
        category = c.category, language = c.language, favorite = favorites[url] == true,
        text = '󰔂 ' .. (pos + 1) .. ' ' .. utf8_cut(c.name, 16),
        tooltip = c.name .. (favorites[url] and ' ★' or '') .. '\n' .. where
            .. '\nclick: channels · right-click: next · middle-click: last channel',
    }), '\n')
    f:close()
end

-- Every channel for the bar's search, with favorites and recent channels by number.
local function write_channels()
    local playlist = mp.get_property_native('playlist') or {}
    local list, number_of = {}, {}
    for i, item in ipairs(playlist) do
        local c = channel_info(item.filename, item.title ~= '' and item.title or nil)
        number_of[item.filename] = i
        list[i] = { n = i, name = c.name, category = c.category, language = c.language or '',
            tags = table.concat(c.tags, ' · '), favorite = favorites[item.filename] == true }
    end
    local favs, recents = {}, {}
    for _, c in ipairs(list) do
        if c.favorite then favs[#favs + 1] = c.n end
    end
    for _, url in ipairs(recent) do
        if number_of[url] then recents[#recents + 1] = number_of[url] end
    end
    local f = open_for_write(expand(o.runtime_dir) .. '/channels.json')
    if not f then return end
    f:write(utils.format_json({ channels = list, favorites = favs, recent = recents }), '\n')
    f:close()
end

mp.register_event('shutdown', function()
    os.remove(now_file())
    os.remove(expand(o.runtime_dir) .. '/channels.json')
end)

mp.register_event('start-file', function()
    local pos = mp.get_property_number('playlist-pos') or -1
    current.pos = pos
    current.title = pos >= 0 and playlist_title(pos) or nil
    current.url = mp.get_property('path')
    if pos >= 0 then show_banner() end   -- at once; streams can take seconds to open
end)

mp.register_event('file-loaded', function()
    consecutive_failures = 0
    show_banner()   -- again: the timer restarts once the picture is there
    write_now()
    write_channels()
end)

-- Remembered from a hook, which mpv waits for, rather than from file-loaded: a
-- late event handler can see the next channel or none, and if mpv is already
-- quitting it kills the first run's mkdir.
mp.add_hook('on_preloaded', 50, function()
    remember_channel(mp.get_property('path'))
    push_recent(mp.get_property('path'))
end)

-- ---------------------------------------------------------------------------
-- Auto-reconnect: a live stream that reaches EOF has dropped, not finished
-- ---------------------------------------------------------------------------

local reloads = {}   -- url -> { n = attempts, since = time }

-- mpv has already begun the next entry when end-file fires; playlist-play-index
-- cancels that and reopens the given channel.
local function replay(pos, reason)
    osd(reason)
    mp.commandv('playlist-play-index', tostring(pos))
end

local function reconnect_after_eof()
    local url, pos = current.url, current.pos
    if not o.reload_on_eof or not url or not pos or pos < 0 then return end
    local now = mp.get_time()
    local r = reloads[url]
    if not r or now - r.since > o.reload_window then
        r = { n = 0, since = now }
        reloads[url] = r
    end
    local title = current.title or url
    if r.n >= o.reload_max then
        msg.warn(title .. ' keeps dropping; stopping')
        mp.commandv('stop', 'keep-playlist')
        osd(string.format('✗  %s keeps dropping — r retries · ENTER picks a channel', title), 6)
        return
    end
    r.n = r.n + 1
    replay(pos, string.format('⟳  %s dropped — reconnecting (%d/%d)', title, r.n, o.reload_max))
end

-- ---------------------------------------------------------------------------
-- Failure handling: skip dead channels, but stop zapping if everything fails
-- ---------------------------------------------------------------------------

local retried = {}   -- url -> time of the last automatic retry

local function handle_load_error(ev)
    local title = current.title or '?'
    local url, pos = current.url, current.pos
    -- A channel tv-check saw alive most likely just hiccuped (CDNs drop the odd
    -- first segment): play it again once before treating it as dead.
    -- (on_load_fail can't do this: mpv only re-opens when the URL changes.)
    -- Known-dead channels are skipped straight away.
    if url and pos and pos >= 0 and known_state(url) == true then
        local now = mp.get_time()
        if not retried[url] or now - retried[url] > 60 then
            retried[url] = now
            msg.info('load failed for ' .. title .. '; retrying once')
            replay(pos, string.format('⟳  %s failed to load — retrying', title))
            return
        end
    end
    consecutive_failures = consecutive_failures + 1
    if consecutive_failures >= o.max_failures then
        msg.warn(string.format('%d consecutive channel failures; stopping', consecutive_failures))
        -- stop keeps the window (idle=yes in the profile) and the playlist
        mp.commandv('stop', 'keep-playlist')
        osd(string.format('✗  %d channels in a row failed (dead links, or no connection).\nPGDN keeps going · ENTER picks a channel · r retries',
            consecutive_failures), 8)
        consecutive_failures = 0
    else
        osd(string.format('✗  %s unavailable (%s) — skipping', title, ev.file_error or 'load error'), 3)
    end
end

mp.register_event('end-file', function(ev)
    if ev.reason == 'eof' then
        reconnect_after_eof()
    elseif ev.reason == 'error' then
        handle_load_error(ev)
    end
end)

-- ---------------------------------------------------------------------------
-- Channel menu (uosc, grouped, searchable) with select.lua fallback
-- ---------------------------------------------------------------------------

-- mpv's flat playlist picker, for when uosc isn't running. uosc can come from the
-- mpv config or from the tv launcher, so callers just try it first: a message to
-- a script that isn't loaded fails quietly.
local function select_playlist()
    mp.commandv('script-binding', 'select/select-playlist')
end

-- Every playlist entry with what the menus show: tidy name, category, tags,
-- number, favorite and dead marks. Both menus are built from this.
local function channel_list()
    refresh_meta()
    refresh_health()
    local playlist = mp.get_property_native('playlist') or {}
    local channels = {}
    for i, item in ipairs(playlist) do
        local c = channel_info(item.filename, item.title ~= '' and item.title or nil)
        c.number = i
        c.active = item.current or false
        c.dead = known_state(item.filename) == false
        c.favorite = favorites[item.filename] == true
        channels[#channels + 1] = c
    end
    return channels
end

local function menu_item(c, with_category)
    local hint = {}
    if with_category then hint[#hint + 1] = c.category end
    for _, tag in ipairs(c.tags) do hint[#hint + 1] = tag end
    if c.dead then hint[#hint + 1] = '✗' end
    hint[#hint + 1] = tostring(c.number)
    return {
        title = (c.favorite and '★ ' or '') .. c.name,
        hint = table.concat(hint, '  ·  '),
        value = c.url,
        active = c.active,
        muted = c.dead,
    }
end

-- Menus answer through menu-event (below), so starring a row (Ctrl+S) can
-- update the menu in place instead of closing it.
local MENU_CALLBACK = { mp.get_script_name(), 'menu-event' }
local FOOTNOTE = 'type to search · Ctrl+S stars · TAB last channel'

local function grouped_menu()
    local channels = channel_list()
    if #channels == 0 then return nil end
    local by_url, by_category, favs = {}, {}, {}
    for _, c in ipairs(channels) do
        by_url[c.url] = c
        by_category[c.category] = by_category[c.category] or {}
        table.insert(by_category[c.category], menu_item(c))
        if c.favorite then favs[#favs + 1] = menu_item(c, true) end
    end
    local items, selected = {}, 1
    local function group(title, list, active)
        items[#items + 1] = { title = title, hint = tostring(#list), items = list, active = active }
        return #items
    end
    if #favs > 0 then group('★ Favorites', favs) end
    local recents = {}
    for _, url in ipairs(recent) do
        if by_url[url] then recents[#recents + 1] = menu_item(by_url[url], true) end
    end
    if #recents > 0 then group('↺ Recent', recents) end
    if #items > 0 then items[#items].separator = true end
    local playing = current.url and by_url[current.url]
    local order = {}
    for _, cat in ipairs(CATEGORIES) do order[#order + 1] = cat[1] end
    order[#order + 1] = OTHER
    for _, name in ipairs(order) do
        if by_category[name] then
            local i = group(name, by_category[name], playing and playing.category == name or false)
            if playing and playing.category == name then selected = i end
        end
    end
    return {
        type = 'tv-channels', title = 'Channels', items = items, selected_index = selected,
        search_submenus = true, callback = MENU_CALLBACK, bind_keys = { 'ctrl+s' },
        footnote = FOOTNOTE .. ' · / all channels',
    }
end

local function flat_menu()
    local channels = channel_list()
    if #channels == 0 then return nil end
    local items, selected = {}, 1
    for i, c in ipairs(channels) do
        items[i] = menu_item(c, true)
        if c.active then selected = i end
    end
    return {
        type = 'tv-all-channels', title = 'All channels', items = items, selected_index = selected,
        search_style = 'palette', callback = MENU_CALLBACK, bind_keys = { 'ctrl+s' },
        footnote = FOOTNOTE .. ' · c by category',
    }
end

local menu_builders = { ['tv-channels'] = grouped_menu, ['tv-all-channels'] = flat_menu }

local function open_menu(menu)
    if not menu then
        osd('Playlist is empty')
        return
    end
    -- One value only: older mpv (0.37) also returns a nil error, which commandv rejects.
    if not mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu)) then
        select_playlist()
    end
end

-- ENTER / c: Favorites, Recent, then the categories, on the current channel's.
local function open_channel_menu() open_menu(grouped_menu()) end
-- / and Shift+ENTER: every channel in one list, search box open.
local function open_all_channels() open_menu(flat_menu()) end

local function play_url(url)
    for i, item in ipairs(mp.get_property_native('playlist') or {}) do
        if item.filename == url then
            mp.commandv('playlist-play-index', tostring(i - 1))
            return true
        end
    end
    return false
end

local function toggle_favorite(url)
    if not url then return end
    favorites[url] = not favorites[url] or nil
    save_favorites()
    if url == current.url then
        write_now()
        if banner_shown then draw_banner() end
    end
    write_channels()
    return favorites[url] == true
end

mp.register_script_message('menu-event', function(json)
    local ev = utils.parse_json(json)
    if type(ev) ~= 'table' then return end
    local menu_type = ev.menu_id and ev.menu_id:match('^tv%-all') and 'tv-all-channels' or nil
    if ev.type == 'activate' and type(ev.value) == 'string' then
        for name in pairs(menu_builders) do mp.commandv('script-message-to', 'uosc', 'close-menu', name) end
        play_url(ev.value)
    elseif ev.type == 'key' and ev.key == 'ctrl+s' and type(ev.selected_item) == 'table'
        and type(ev.selected_item.value) == 'string' then
        toggle_favorite(ev.selected_item.value)
        for name, build in pairs(menu_builders) do
            if not menu_type or menu_type == name then
                local m = build()
                if m then mp.commandv('script-message-to', 'uosc', 'update-menu', utils.format_json(m)) end
            end
        end
    end
end)

-- ---------------------------------------------------------------------------
-- Remote-style channel number entry
-- ---------------------------------------------------------------------------

local digits, digit_timer = '', nil

local function cancel_digit_timer()
    if digit_timer then
        digit_timer:kill()
        digit_timer = nil
    end
end

local function commit_digits()
    cancel_digit_timer()
    local n = tonumber(digits)
    digits = ''
    if not n then return end
    local count = mp.get_property_number('playlist-count') or 0
    if n < 1 or n > count then
        osd(string.format('No channel %d (1–%d)', n, count), 2)
        return
    end
    mp.commandv('playlist-play-index', tostring(n - 1))
end

local function push_digit(d)
    cancel_digit_timer()
    local count = mp.get_property_number('playlist-count') or 0
    local max_len = #tostring(math.max(count, 1))
    digits = digits .. d
    if #digits > max_len then digits = digits:sub(-max_len) end
    osd('Channel ' .. digits .. '_', o.digit_timeout + 0.2)
    if #digits >= max_len then
        commit_digits()
    else
        digit_timer = mp.add_timeout(o.digit_timeout, commit_digits)
    end
end

for d = 0, 9 do
    local s = tostring(d)
    mp.add_key_binding(s, 'tv-digit-' .. s, function() push_digit(s) end)
    mp.add_key_binding('KP' .. s, 'tv-kp-digit-' .. s, function() push_digit(s) end)
end

local function enter()
    if digits ~= '' then
        commit_digits()
    else
        open_channel_menu()
    end
end

mp.add_key_binding('ENTER', 'tv-enter', enter)
mp.add_key_binding('KP_ENTER', 'tv-kp-enter', enter)
mp.add_key_binding('c', 'tv-channels', open_channel_menu)
-- Bound here rather than in input.conf so they come with `stow tv` and stay out of
-- normal playback (mpv's default PGUP/PGDWN seek chapters).
mp.add_key_binding('PGUP', 'tv-prev', function() mp.command('playlist-prev') end)
mp.add_key_binding('PGDWN', 'tv-next', function() mp.command('playlist-next') end)

-- TAB: back to the channel before this one, like a remote's "last" button.
local function last_channel()
    local url = recent[1] == current.url and recent[2] or recent[1]
    if not url or not play_url(url) then osd('No earlier channel yet', 2) end
end
mp.add_key_binding('TAB', 'tv-last', last_channel)
-- s stars the channel playing (f stays fullscreen).
mp.add_key_binding('s', 'tv-star', function()
    if not current.url then return end
    local on = toggle_favorite(current.url)
    if not banner_shown then
        osd((on and '★  Starred ' or 'Unstarred ') .. channel_info(current.url, current.title).name, 2)
    end
end)
-- For `tv --ctl` (the Omarchy bar)
mp.register_script_message('tv-menu', function() open_channel_menu() end)
mp.register_script_message('tv-next', function() mp.command('playlist-next') end)
mp.register_script_message('tv-prev', function() mp.command('playlist-prev') end)
mp.register_script_message('tv-last', last_channel)
mp.register_script_message('tv-star', function() if current.url then toggle_favorite(current.url) end end)
mp.register_script_message('tv-play', function(n)
    local count = mp.get_property_number('playlist-count') or 0
    n = tonumber(n)
    if n and n >= 1 and n <= count then mp.commandv('playlist-play-index', tostring(n - 1)) end
end)
mp.add_key_binding('/', 'tv-search', open_all_channels)
mp.add_key_binding('Shift+ENTER', 'tv-search-alt', open_all_channels)
-- The digits and / above take over mpv's default volume keys (9/0, / and *).
local function volume(step)
    return function() mp.command('osd-msg-bar add volume ' .. step) end
end
mp.add_key_binding('-', 'tv-volume-down', volume(-2), { repeatable = true })
mp.add_key_binding('+', 'tv-volume-up', volume(2), { repeatable = true })
mp.add_key_binding('=', 'tv-volume-up-alt', volume(2), { repeatable = true })
-- Older mpv (0.37) doesn't know KP_ADD/KP_SUBTRACT and warns about binding them.
for _, key in ipairs(mp.get_property_native('input-key-list') or {}) do
    if key == 'KP_SUBTRACT' then
        mp.add_key_binding(key, 'tv-kp-volume-down', volume(-2), { repeatable = true })
    elseif key == 'KP_ADD' then
        mp.add_key_binding(key, 'tv-kp-volume-up', volume(2), { repeatable = true })
    end
end
mp.add_key_binding('M', 'tv-mute', function() mp.command('osd-msg cycle mute') end)
-- Also works after a stop: current still holds the channel that gave up.
mp.add_key_binding('r', 'tv-reload', function()
    if not current.pos or current.pos < 0 then
        osd('No channel to reload — press ENTER to pick one', 3)
        return
    end
    if current.url then reloads[current.url] = nil end
    replay(current.pos, '⟳  Reloading ' .. (current.title or 'channel'))
end)
mp.add_key_binding('BS', 'tv-digit-clear', function()
    if digits ~= '' then
        cancel_digit_timer()
        digits = ''
        osd('', 0.1)
    end
end)

refresh_meta()
refresh_health()
load_lists()
load_theme()
mp.add_periodic_timer(3, function()
    if load_theme() and banner_shown then draw_banner() end
end)

if o.dump ~= '' then
    local f = assert(io.open(expand(o.dump), 'w'))
    for url, e in pairs(meta.by_url) do
        f:write(e.group, '\t', e.title, '\t', url, '\n')
    end
    f:close()
    mp.command('quit')
end
