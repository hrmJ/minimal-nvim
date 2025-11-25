local M = {}

-- Get list of changed files from git diff
function M.get_changed_files(base_branch)
  base_branch = base_branch or "develop"
  
  local cmd = string.format("git diff %s --name-only", base_branch)
  local handle = io.popen(cmd)
  if not handle then
    return nil, "Failed to run git command"
  end
  
  local result = handle:read("*a")
  handle:close()
  
  local files = {}
  for file in result:gmatch("[^\r\n]+") do
    if file ~= "" then
      table.insert(files, file)
    end
  end
  
  return files
end

-- Parse file list into a tree structure
function M.build_tree(files)
  local tree = {}
  
  for _, filepath in ipairs(files) do
    local parts = vim.split(filepath, "/")
    local current = tree
    
    for i, part in ipairs(parts) do
      local is_file = (i == #parts)
      
      if not current[part] then
        current[part] = {
          name = part,
          is_file = is_file,
          children = is_file and nil or {}
        }
      end
      
      if not is_file then
        current = current[part].children
      end
    end
  end
  
  return tree
end

-- State to track expanded folders
M.expanded = {}

-- Collapse single-child folder chains
local function collapse_chain(node, name)
  local chain = { name }
  local current = node
  
  while current.children do
    local keys = vim.tbl_keys(current.children)
    -- Stop if we have files at this level or multiple children
    if #keys ~= 1 or current.children[keys[1]].is_file then
      break
    end
    
    local child_key = keys[1]
    table.insert(chain, child_key)
    current = current.children[child_key]
  end
  
  return table.concat(chain, "/"), current
end

-- Render tree to lines
local function render_node(node, lines, indent, path)
  local keys = vim.tbl_keys(node)
  table.sort(keys)
  
  for _, key in ipairs(keys) do
    local item = node[key]
    
    if item.is_file then
      table.insert(lines, { text = string.rep("  ", indent) .. "  " .. item.name, path = path .. "/" .. item.name })
    else
      local display_name, collapsed_node = collapse_chain(item, item.name)
      local full_path = path .. "/" .. display_name
      local is_expanded = M.expanded[full_path]
      local icon = is_expanded and "▼" or "▶"
      
      table.insert(lines, { text = string.rep("  ", indent) .. icon .. " " .. display_name, path = full_path, is_folder = true })
      
      if is_expanded and collapsed_node.children then
        render_node(collapsed_node.children, lines, indent + 1, full_path)
      end
    end
  end
end

function M.render_tree(tree)
  local lines = {}
  render_node(tree, lines, 0, "")
  return lines
end

-- Open PR review window
function M.open()
  local files = M.get_changed_files()
  if not files or #files == 0 then
    vim.notify("No changed files found", vim.log.levels.WARN)
    return
  end
  
  local tree = M.build_tree(files)
  
  -- Create buffer
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_option(buf, 'bufhidden', 'wipe')
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Create window
  vim.cmd('vsplit')
  local win = vim.api.nvim_get_current_win()
  vim.api.nvim_win_set_buf(win, buf)
  vim.api.nvim_win_set_width(win, 40)
  
  -- Store tree in buffer variable
  vim.api.nvim_buf_set_var(buf, 'pr_tree', tree)
  
  -- Render initial tree
  M.refresh_buffer(buf)
  
  -- Set up keymaps
  vim.keymap.set('n', '<CR>', function() M.toggle_folder(buf) end, { buffer = buf })
  vim.keymap.set('n', 'q', '<cmd>q<cr>', { buffer = buf })
end

function M.refresh_buffer(buf)
  local tree = vim.api.nvim_buf_get_var(buf, 'pr_tree')
  local lines = M.render_tree(tree)
  
  vim.api.nvim_buf_set_option(buf, 'modifiable', true)
  local text_lines = vim.tbl_map(function(l) return l.text end, lines)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, text_lines)
  vim.api.nvim_buf_set_option(buf, 'modifiable', false)
  
  -- Store line metadata
  vim.api.nvim_buf_set_var(buf, 'pr_lines', lines)
end

function M.toggle_folder(buf)
  local cursor = vim.api.nvim_win_get_cursor(0)
  local line_idx = cursor[1]
  
  local lines = vim.api.nvim_buf_get_var(buf, 'pr_lines')
  local line = lines[line_idx]
  
  if line and line.is_folder then
    M.expanded[line.path] = not M.expanded[line.path]
    M.refresh_buffer(buf)
  end
end

return M
