local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local function git_diff_files(opts)
	opts = opts or {}
	local base_branch = opts.base_branch or "origin/develop"

	-- Get list of changed files
	local cmd = string.format("git diff --name-only %s..HEAD", base_branch)
	local handle = io.popen(cmd)
	local files = {}

	if handle then
		for line in handle:lines() do
			table.insert(files, line)
		end
		handle:close()
	end

	pickers
		.new(opts, {
			prompt_title = string.format("Git Diff Files (%s..HEAD)", base_branch),
			finder = finders.new_table({
				results = files,
			}),
			previewer = previewers.new_termopen_previewer({
				get_command = function(entry)
					return { "git", "diff", "--color=always", base_branch .. "..HEAD", "--", entry.value }
				end,
				scroll_fn = function(self, direction)
					if not self.state or not self.state.termopen_id then
						return
					end
					local input = direction > 0 and [[]] or [[]]
					vim.api.nvim_chan_send(self.state.termopen_id, input)
				end,
			}),
			attach_mappings = function(prompt_bufnr, map)
				actions.select_default:replace(function()
					local selection = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					-- Just open the file normally
					vim.cmd("edit " .. selection[1])
				end)
				return true
			end,
		})
		:find()
end

-- Create command
vim.api.nvim_create_user_command("TelescopeGitDiff", function(opts)
	git_diff_files({ base_branch = opts.args ~= "" and opts.args or nil })
end, { nargs = "?" })

vim.api.nvim_set_keymap(
	"n",
	"<leader>rd",
	"<cmd>TelescopeGitDiff<cr>",
	{ noremap = true, silent = true, desc = "Telescope git diff" }
)

return git_diff_files
