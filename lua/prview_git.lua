local M = {}

-- Get change magnitude for a file (returns number of asterisks)
function M.get_change_magnitude(filepath, base_branch)
  base_branch = base_branch or "develop"
  
  -- Remove leading slash
  local clean_path = filepath:gsub("^/", "")
  
  local cmd = string.format("git diff %s --numstat -- %s", base_branch, vim.fn.shellescape(clean_path))
  local handle = io.popen(cmd)
  if not handle then
    return ""
  end
  
  local result = handle:read("*a")
  handle:close()
  
  if result == "" then
    return ""
  end
  
  local added, deleted = result:match("^(%d+)%s+(%d+)")
  if not added or not deleted then
    return ""
  end
  
  local total_changes = tonumber(added) + tonumber(deleted)
  
  if total_changes <= 5 then
    return "*"
  elseif total_changes <= 20 then
    return "**"
  elseif total_changes <= 50 then
    return "***"
  else
    return "****"
  end
end

return M
