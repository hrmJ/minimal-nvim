local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local conf = require("telescope.config").values
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")

local M = {}

function M.pick_tmux_pane(opts)
	opts = opts or {}
	local output = vim.fn.system("tmux list-panes -F '#{pane_id}:#{pane_title}:#{pane_current_command}'")
	local panes = {}
	for line in output:gmatch("[^\n]+") do
		local id, title, cmd = line:match("^(%%[^:]+):([^:]*):(.+)$")
		if id then
			table.insert(panes, { id = id, title = title, cmd = cmd })
		end
	end

	pickers
		.new(opts, {
			prompt_title = "Tmux Panes",
			finder = finders.new_table({
				results = panes,
				entry_maker = function(entry)
					local display = entry.id .. " | " .. entry.cmd
					if entry.title ~= "" then
						display = entry.id .. " | " .. entry.title .. " | " .. entry.cmd
					end
					return { value = entry, display = display, ordinal = display }
				end,
			}),
			sorter = conf.generic_sorter(opts),
			previewer = previewers.new_termopen_previewer({
				title = "Pane Content",
				get_command = function(entry)
					return { "tmux", "capture-pane", "-t", entry.value.id, "-e", "-p", "-J" }
				end,
			}),
			attach_mappings = function(prompt_bufnr)
				actions.select_default:replace(function()
					local entry = action_state.get_selected_entry()
					actions.close(prompt_bufnr)
					vim.fn.system({ "tmux", "select-pane", "-t", entry.value.id })
					vim.fn.system({ "tmux", "resize-pane", "-Z", "-t", entry.value.id })
				end)
				return true
			end,
		})
		:find()
end

return M
