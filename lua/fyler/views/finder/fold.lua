local M = {}

--- Calculate the fold level for a line based on its indentation
--- Each directory level adds 2 spaces of indentation
---@param lnum integer Line number
---@return string Fold level expression result
function M.foldexpr(lnum)
  local line = vim.fn.getline(lnum)
  
  -- Empty lines inherit fold level from previous line
  if line:match("^%s*$") then
    return "="
  end
  
  -- Count leading spaces (each directory level = 2 spaces)
  local spaces = line:match("^%s*")
  local indent_level = math.floor(#spaces / 2)
  
  -- Get next line to determine if this is a fold start
  local next_line = vim.fn.getline(lnum + 1)
  
  -- If no next line or next line is empty, just return current level
  if next_line == "" or next_line:match("^%s*$") then
    return tostring(indent_level)
  end
  
  local next_spaces = next_line:match("^%s*") or ""
  local next_indent = math.floor(#next_spaces / 2)
  
  -- If next line is more indented, this line starts a fold
  if next_indent > indent_level then
    return ">" .. tostring(indent_level + 1)
  end
  
  -- Otherwise, return the current indent level as the fold level
  return tostring(indent_level)
end

--- Custom fold text to display when a directory is folded
---@return string The text to display for folded lines
function M.foldtext()
  local line = vim.fn.getline(vim.v.foldstart)
  local fold_size = vim.v.foldend - vim.v.foldstart
  
  -- Parse the line to extract components
  local parser = require("fyler.views.finder.parser")
  local name = parser.parse_name(line)
  
  -- Get indentation
  local indent = line:match("^(%s*)")
  
  -- Extract icon (everything between indent and ref_id)
  -- Format: <indent><icon> /<ref_id> <name>
  local icon = ""
  local icon_match = line:match("^%s*(.-)%s*/")
  if icon_match and icon_match ~= "" then
    icon = icon_match .. " "
  end
  
  -- Build fold text without concealed ref_id
  local fold_text = indent .. icon .. name
  
  -- Add fold indicator
  if fold_size > 0 then
    return fold_text .. " ... [" .. fold_size .. " hidden]"
  else
    return fold_text
  end
end

--- Update fold state after tree structure changes
--- This ensures folds are recalculated when the tree changes
---@param bufnr integer Buffer number
function M.sync_folds(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  
  vim.schedule(function()
    vim.api.nvim_buf_call(bufnr, function()
      -- Update folds by recomputing fold levels
      -- This will re-evaluate foldexpr for all lines
      vim.fn.feedkeys("zx", "n")
    end)
  end)
end

return M
