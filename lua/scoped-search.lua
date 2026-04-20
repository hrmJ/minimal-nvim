local M = {}

local current_dir = nil

function M.open(dir, query, stay_normal)
  current_dir = dir or vim.fn.expand("%:p:h")
  if current_dir == "" or vim.fn.isdirectory(current_dir) == 0 then
    vim.notify("No valid directory for current buffer", vim.log.levels.ERROR)
    return
  end
  require("telescope").extensions.live_grep_args.live_grep_args({
    cwd = current_dir,
    prompt_title = "Grep: " .. vim.fn.fnamemodify(current_dir, ":~"),
    default_text = query or "",
    attach_mappings = function(_, map)
      map("n", "-", function(prompt_bufnr)
        local parent = vim.fn.fnamemodify(current_dir, ":h")
        if parent == current_dir then return end
        local current_query = require("telescope.actions.state").get_current_line()
        require("telescope.actions").close(prompt_bufnr)
        vim.schedule(function()
          M.open(parent, current_query, true)
        end)
      end)
      return true
    end,
  })
  if stay_normal then
    vim.schedule(function()
      vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "n", false)
    end)
  end
end

vim.api.nvim_create_user_command("ScopedSearch", function() M.open() end, {})

return M
