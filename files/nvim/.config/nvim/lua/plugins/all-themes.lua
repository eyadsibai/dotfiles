return {
	-- Load all theme plugins lazily so colorschemes are available for hot-reloading.
	-- Omarchy 4 generates the remaining theme specs on top of aether below.
	{
		"ribru17/bamboo.nvim",
		lazy = true,
		priority = 1000,
	},
	-- Name and branch must match Omarchy 4's generated theme spec
	-- (default/themed/neovim.lua.tpl). lazy merges specs by url and lets an
	-- explicit name rename the merged plugin, so a bare "bjarneo/aether.nvim"
	-- here builds the cache into lazy/aether.nvim while every aether-themed
	-- Omarchy 4 install renames it to lazy/aether at runtime -- a directory the
	-- package never shipped. That cost a network clone on first launch, and the
	-- theme fell back to tokyonight until nvim was restarted.
	{
		"bjarneo/aether.nvim",
		branch = "v3",
		name = "aether",
		lazy = true,
		priority = 1000,
	},
	{
		"bjarneo/hackerman.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"catppuccin/nvim",
		name = "catppuccin",
		lazy = true,
		priority = 1000,
	},
	{
		"neanias/everforest-nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"kepano/flexoki-neovim",
		lazy = true,
		priority = 1000,
	},
	{
		"ellisonleao/gruvbox.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"rebelot/kanagawa.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"tahayvr/matteblack.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"EdenEast/nightfox.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"rose-pine/neovim",
		name = "rose-pine",
		lazy = true,
		priority = 1000,
	},
	{
		"ficcdaf/ashen.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"folke/tokyonight.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"OldJobobo/retro-82.nvim",
		lazy = true,
		priority = 1000,
	},
	{
		"omacom-io/lumon.nvim",
		lazy = true,
		priority = 1000,
	},
}
