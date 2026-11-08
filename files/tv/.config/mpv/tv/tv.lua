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
--   * Channel menus (uosc): ENTER or c groups channels by group-title, / lists
--     them all with the search open. Both show the same names and numbers.
--     Falls back to mpv's built-in select.lua.
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
--   osd_seconds=2.5            how long the channel banner stays up
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
    local f = io.open(path, 'w')
    if not f then
        -- First run: create the state dir (synchronously; 'run' is async) and retry.
        local dir = path:match('^(.*)/[^/]+$')
        if dir then
            mp.command_native({ name = 'subprocess', args = { 'mkdir', '-p', dir }, playback_only = false })
            f = io.open(path, 'w')
        end
    end
    if f then
        f:write(url, '\n')
        f:close()
    end
end

local function show_banner()
    local pos = mp.get_property_number('playlist-pos') or -1
    local count = mp.get_property_number('playlist-count') or 0
    if pos < 0 then return end
    local e = entry_for(mp.get_property('path'))
    local title = mp.get_property('media-title') or playlist_title(pos)
    local group = e and e.group and ('   ·   ' .. e.group) or ''
    osd(string.format('%d/%d   %s%s', pos + 1, count, title, group))
end

mp.register_event('start-file', function()
    local pos = mp.get_property_number('playlist-pos') or -1
    current.pos = pos
    current.title = pos >= 0 and playlist_title(pos) or nil
    current.url = mp.get_property('path')
end)

mp.register_event('file-loaded', function()
    consecutive_failures = 0
    show_banner()
end)

-- Remembered from a hook, which mpv waits for, rather than from file-loaded: a
-- late event handler can see the next channel or none, and if mpv is already
-- quitting it kills the first run's mkdir.
mp.add_hook('on_preloaded', 50, function()
    remember_channel(mp.get_property('path'))
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

-- Every channel as a uosc menu item, with its group. Both menus are built from
-- this, so they show the same names, numbers and dead-channel marks.
local function channel_list()
    refresh_meta()
    refresh_health()
    local playlist = mp.get_property_native('playlist') or {}
    local channels = {}
    for i, item in ipairs(playlist) do
        local e = entry_for(item.filename)
        local title = (e and e.title and e.title ~= '') and e.title
            or ((item.title and item.title ~= '') and item.title or item.filename)
        local dead = known_state(item.filename) == false
        channels[#channels + 1] = {
            group = e and e.group or 'Other',
            title = title,
            hint = dead and (tostring(i) .. '  ✗') or tostring(i),
            value = { 'playlist-play-index', tostring(i - 1) },
            active = item.current or false,
            muted = dead,
        }
    end
    return channels
end

local function open_menu(menu)
    -- One value only: older mpv (0.37) also returns a nil error, which commandv rejects.
    if not mp.commandv('script-message-to', 'uosc', 'open-menu', utils.format_json(menu)) then
        select_playlist()
    end
end

-- ENTER / c: channels grouped by group-title, starting on the current channel's group.
local function open_channel_menu()
    local channels = channel_list()
    if #channels == 0 then
        osd('Playlist is empty')
        return
    end
    local by_group, order = {}, {}
    for _, c in ipairs(channels) do
        if not by_group[c.group] then
            by_group[c.group] = {}
            order[#order + 1] = c.group
        end
        table.insert(by_group[c.group], c)
    end
    local items, selected = {}, 1
    for i, group in ipairs(order) do
        local list, active = by_group[group], false
        for _, c in ipairs(list) do
            if c.active then active = true break end
        end
        if active then selected = i end
        items[i] = { title = group, hint = tostring(#list), items = list, active = active }
    end
    open_menu({
        type = 'tv-channels',
        title = 'Channels',
        items = items,
        selected_index = selected,
        search_submenus = true,
        footnote = 'type to search · / all channels · ENTER switches',
    })
end

-- / and Shift+ENTER: every channel in one list, search box open.
local function open_all_channels()
    local channels = channel_list()
    if #channels == 0 then
        osd('Playlist is empty')
        return
    end
    local selected = 1
    for i, c in ipairs(channels) do
        if c.active then selected = i break end
    end
    open_menu({
        type = 'tv-all-channels',
        title = 'All channels',
        items = channels,
        selected_index = selected,
        search_style = 'palette',
        footnote = 'type to search · ENTER switches · c by group',
    })
end

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

if o.dump ~= '' then
    local f = assert(io.open(expand(o.dump), 'w'))
    for url, e in pairs(meta.by_url) do
        f:write(e.group, '\t', e.title, '\t', url, '\n')
    end
    f:close()
    mp.command('quit')
end
