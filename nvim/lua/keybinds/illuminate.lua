return function(_, opts)
	local illuminate = require("illuminate")

	illuminate.configure(opts)

	local function goto_reference(dir)
		local cmd = "goto_" .. dir .. "_reference"
		return function()
			illuminate[cmd](false)
		end
	end

	vim.keymap.set("n", "]]", goto_reference("next"), { desc = "Next Reference" })
	vim.keymap.set("n", "[[", goto_reference("prev"), { desc = "Previous Reference" })
end
