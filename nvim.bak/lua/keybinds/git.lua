return function(bufnr)
	local gs = require("gitsigns")

	local function stage_current_hunk()
		gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end

	local function reset_current_hunk()
		gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
	end

	local function blame_line()
		gs.blame_line({ full = true })
	end

	local function toggle_diffs()
		gs.diffthis("~")
	end

	-- Hunk navigation.
	vim.keymap.set("n", "]h", gs.next_hunk, { buffer = bufnr, desc = "Next Git Hunk" })
	vim.keymap.set("n", "[h", gs.next_hunk, { buffer = bufnr, desc = "Previous Git Hunk" })

	-- Hunk actions.
	vim.keymap.set("n", "<leader>ga", gs.stage_hunk, { buffer = bufnr, desc = "Git Add Hunk" })
	vim.keymap.set("n", "<leader>gr", gs.reset_hunk, { buffer = bufnr, desc = "Git Reset Hunk" })
	vim.keymap.set("v", "<leader>ga", stage_current_hunk, { buffer = bufnr, desc = "Git Add Hunk" })
	vim.keymap.set("v", "<leader>gr", reset_current_hunk, { buffer = bufnr, desc = "Git Reset Hunk" })

	-- Undoing and previewing hunks.
	vim.keymap.set("n", "<leader>gu", gs.undo_stage_hunk, { buffer = bufnr, desc = "Undo Git Add Hunk" })
	vim.keymap.set("n", "<leader>gp", gs.preview_hunk, { buffer = bufnr, desc = "Preview Git Add Hunk" })

	-- Buffer actions.
	vim.keymap.set("n", "<leader>gA", gs.stage_buffer, { buffer = bufnr, desc = "Git Add current file" })
	vim.keymap.set("n", "<leader>gR", gs.reset_buffer, { buffer = bufnr, desc = "Git Reset current file" })

	-- Blame.
	vim.keymap.set("n", "<leader>gb", blame_line, { buffer = bufnr, desc = "Git Blame Line" })
	vim.keymap.set("n", "<leader>gB", gs.toggle_current_line_blame, { buffer = bufnr, desc = "Toggle Git Blame Line" })

	-- Diffs.
	vim.keymap.set("n", "<leader>gd", gs.diffthis, { buffer = bufnr, desc = "View Git Diffs" })
	vim.keymap.set("n", "<leader>gD", toggle_diffs, { buffer = bufnr, desc = "Toggle Git Diffs" })

	-- Text object for hunks.
	vim.keymap.set({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", { buffer = bufnr, desc = "Select Git Hunk" })
end
