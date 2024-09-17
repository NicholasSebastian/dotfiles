local harpoon = require("harpoon")

return function(harpoon_telescope)
	local show_harpoon = function()
		harpoon_telescope("<Del>") -- Del key in Harpoon window removes files.
	end

	vim.keymap.set("n", "<C-[>", show_harpoon)
	vim.keymap.set("n", "<leader>h", show_harpoon, { desc = "Open Harpoon Explorer" })
	vim.keymap.set("n", "<Esc>", "<nop>") -- By default, the esc key in normal mode opens Harpoon for some reason.

	vim.keymap.set("n", "<leader>a", function()
		harpoon:list():add()
	end, { desc = "Add current file to Harpoon" })

	vim.keymap.set("n", "<A-1>", function()
		harpoon:list():select(1)
	end)

	vim.keymap.set("n", "<A-2>", function()
		harpoon:list():select(2)
	end)

	vim.keymap.set("n", "<A-3>", function()
		harpoon:list():select(3)
	end)

	vim.keymap.set("n", "<A-4>", function()
		harpoon:list():select(4)
	end)

	vim.keymap.set("n", "<A-p>", function()
		harpoon:list():prev() -- Navigate to the previous file.
	end)

	vim.keymap.set("n", "<A-n>", function()
		harpoon:list():next() -- Navigate to the next file.
	end)
end
