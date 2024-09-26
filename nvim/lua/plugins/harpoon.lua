-- https://github.com/ThePrimeagen/harpoon/tree/harpoon2
-- ThePrimeAgen's plugin. Allows easy switching between marked files.

return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
	},
	config = function()
		local harpoon = require("harpoon")
		harpoon:setup({})

		-- Creates a Telescope window displaying all the Harpoon files.
		local make_finder = function(files)
			local file_paths = {}
			for _, item in ipairs(files.items) do
				table.insert(file_paths, item.value)
			end
			return require("telescope.finders").new_table({ results = file_paths })
		end

		-- Returns the handler to remove files from Harpoon from the Telescope window.
		local handle_delete = function(files, keybind)
			return function(buffer_id, map)
				map("i", keybind, function()
					local state = require("telescope.actions.state")
					local selected_entry = state.get_selected_entry()
					local current_picker = state.get_current_picker(buffer_id)
					table.remove(files.items, selected_entry.index)
					current_picker:refresh(make_finder(files))
				end)
				return true
			end
		end

		-- Opens the actual Harpoon-Telescope window.
		local function toggle_telescope(keybind)
			local files = harpoon:list()
			local conf = require("telescope.config").values
			local opts = {
				prompt_title = "Harpoon",
				layout_config = {
					height = 0.4,
					width = 0.5,
					preview_cutoff = 120,
				},
				finder = make_finder(files),
				previewer = conf.file_previewer({}),
				sorter = conf.generic_sorter({}),
				attach_mappings = handle_delete(files, keybind),
			}
			require("telescope.pickers").new({}, opts):find()
		end

		local setup_keybinds = require("keybinds/harpoon")
		setup_keybinds(toggle_telescope)
	end,
}
