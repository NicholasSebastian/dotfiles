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

	local function diffthis()
		gs.diffthis("~")
	end

	local function map(mode, l, r, desc)
		vim.keymap.set(mode, l, r, { buffer = bufnr, desc = desc })
	end

	-- Hunk navigation.
	map("n", "]h", gs.next_hunk, "Next Git Hunk")
	map("n", "[h", gs.prev_hunk, "Prev Git Hunk")

	-- Hunk actions.
	map("n", "<leader>gs", gs.stage_hunk, "Git Add section")
	map("n", "<leader>gr", gs.reset_hunk, "Git Reset section")
	map("v", "<leader>gs", stage_current_hunk, "Git Add section")
	map("v", "<leader>gr", reset_current_hunk, "Git Reset section")
	map("n", "<leader>gu", gs.undo_stage_hunk, "Undo Git Add section")
	map("n", "<leader>gp", gs.preview_hunk, "Preview Git section")

	-- Buffer actions.
	map("n", "<leader>gS", gs.stage_buffer, "Git Add the current file")
	map("n", "<leader>gR", gs.reset_buffer, "Git Reset the current file")

	-- Blame.
	map("n", "<leader>gb", blame_line, "Git Blame Line")
	map("n", "<leader>gB", gs.toggle_current_line_blame, "Toggle Git Blame Line")

	-- Diffs.
	map("n", "<leader>gd", gs.diffthis, "View Git Diffs")
	map("n", "<leader>gD", diffthis, "Toggle Git Diffs")

	-- Text object for hunks.
	map({ "o", "x" }, "ih", ":<C-U>Gitsigns select_hunk<CR>", "Gitsigns Select Hunk")
end
