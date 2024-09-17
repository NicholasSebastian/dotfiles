local harpoon = require("harpoon")

local navigate = function(index)
	return function()
		harpoon:list():select(index)
	end
end

return function(harpoon_telescope)
	local show_harpoon = function()
		harpoon_telescope("<Del>") -- Del key in Harpoon window removes files.
	end

	vim.keymap.set("n", "<C-[>", show_harpoon)
	vim.keymap.set("n", "<leader>h", show_harpoon, { desc = "Open Harpoon Explorer" })

	-- By default, the esc key in normal mode opens Harpoon for some reason.
	vim.keymap.set("n", "<Esc>", "<nop>")

	-- Quick navigation via Alt+Number keys.
	vim.keymap.set("n", "<A-1>", navigate(1))
	vim.keymap.set("n", "<A-2>", navigate(2))
	vim.keymap.set("n", "<A-3>", navigate(3))
	vim.keymap.set("n", "<A-4>", navigate(4))
	vim.keymap.set("n", "<A-5>", navigate(5))
	vim.keymap.set("n", "<A-6>", navigate(6))
	vim.keymap.set("n", "<A-7>", navigate(7))
	vim.keymap.set("n", "<A-8>", navigate(8))
	vim.keymap.set("n", "<A-9>", navigate(9))
	vim.keymap.set("n", "<A-0>", navigate(10))

	vim.keymap.set("n", "<leader>a", function()
		harpoon:list():add()
		vim.api.nvim_echo({ { "Current file added to Harpoon.", "None" } }, false, {})
	end, { desc = "Add current file to Harpoon" })

	vim.keymap.set("n", "<A-p>", function()
		harpoon:list():prev() -- Navigate to the previous file.
	end)

	vim.keymap.set("n", "<A-n>", function()
		harpoon:list():next() -- Navigate to the next file.
	end)
end
