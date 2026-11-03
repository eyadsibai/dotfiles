local mp = require("mp")

local uosc_dir = "@uoscDir@"

package.path = table.concat({
    uosc_dir .. "/?.lua",
    uosc_dir .. "/?/init.lua",
    package.path,
}, ";")

-- uosc is installed as a directory with main.lua and support files.
-- Present it to mpv as a normal script named "uosc" while keeping resource lookups
-- relative to the packaged directory.
mp.get_script_directory = function()
    return uosc_dir
end

dofile(uosc_dir .. "/main.lua")

-- Monkey-patch Menu for hjkl navigation (vim-style)
local orig_enable = Menu.enable_key_bindings
function Menu:enable_key_bindings()
    orig_enable(self)
    local hjkl = {{'h', false}, {'j', true}, {'k', true}, {'l', false}}
    local named_mods = {'ctrl', 'shift', 'ctrl+shift'}
    for _, kv in ipairs(hjkl) do
        local key, repeatable = kv[1], kv[2]
        local flags = {repeatable = repeatable, complex = true}
        -- Bind without modifier
        local shortcut = create_shortcut(key)
        local handler = self:create_action(function(info) self:handle_shortcut(shortcut, info) end)
        self:add_key_binding(shortcut.id, {handler, flags})
        -- Bind with each modifier
        for _, mod in ipairs(named_mods) do
            shortcut = create_shortcut(key, mod)
            handler = self:create_action(function(info) self:handle_shortcut(shortcut, info) end)
            self:add_key_binding(shortcut.id, {handler, flags})
        end
    end
end

local orig_handle = Menu.handle_shortcut
function Menu:handle_shortcut(shortcut, info)
    if not self:is_alive() then return end
    if not self.current.search then
        local map = {h = 'left', j = 'down', k = 'up', l = 'right'}
        local mapped = map[shortcut.key]
        if mapped then
            shortcut = create_shortcut(mapped, shortcut.modifiers)
        end
    end
    return orig_handle(self, shortcut, info)
end

-- Position menus at top-right instead of center
local orig_update_coords = Menu.update_coordinates
function Menu:update_coordinates()
    local margin = round(self.item_height / 2)
    local ax = round(display.width - self.current.width - margin - self.padding) + self.offset_x
    self:set_coordinates(
        ax, self.current.top - self.padding,
        ax + self.current.width + self.padding * 2, self.current.top + self.current.height + self.padding
    )
end

local orig_update_dims = Menu.update_dimensions
function Menu:update_dimensions()
    orig_update_dims(self)
    -- Force top position for all menus
    local margin = round(self.item_height / 2)
    for _, menu in ipairs(self.all) do
        menu.top = margin + self.padding
    end
    self:update_coordinates()
end

-- Re-register playlist without hint numbers to prevent text overlap
bind_command('playlist', create_self_updating_menu_opener({
    title = t('Playlist'),
    type = 'playlist',
    list_prop = 'playlist',
    serializer = function(playlist)
        local items = {}
        local force_filename = mp.get_property_native('osd-playlist-entry') == 'filename'
        for index, item in ipairs(playlist) do
            local title = type(item.title) == 'string' and #item.title > 0 and item.title or false
            items[index] = {
                title = (not force_filename and title) and title
                    or (is_protocol(item.filename) and item.filename or serialize_path(item.filename).basename),
                active = item.current,
                value = index,
            }
        end
        return items
    end,
    on_activate = function(event) mp.commandv('set', 'playlist-pos-1', tostring(event.value)) end,
    on_paste = function(event) mp.commandv('loadfile', tostring(event.value), 'append') end,
    on_key = function(event)
        if event.id == 'ctrl+c' and event.selected_item then
            local payload = mp.get_property_native('playlist/' .. (event.selected_item.value - 1) .. '/filename')
            set_clipboard(payload)
        end
    end,
    on_move = function(event)
        local from, to = event.from_index, event.to_index
        mp.commandv('playlist-move', tostring(from - 1), tostring(to - (to > from and 0 or 1)))
    end,
    on_remove = function(event) mp.commandv('playlist-remove', tostring(event.value - 1)) end,
}))
