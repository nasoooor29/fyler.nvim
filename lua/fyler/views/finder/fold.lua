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
  
  -- Return fold text that looks exactly like the original line
  -- No extra indicators or styling - just the line as it would appear normally
  return indent .. icon .. name
end

--- Update fold state after tree structure changes
--- Preserves manual fold state by tracking ref_ids instead of line numbers
---@param bufnr integer Buffer number
function M.sync_folds(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return
  end
  
  vim.schedule(function()
    vim.api.nvim_buf_call(bufnr, function()
      -- Save current fold state using ref_ids to handle line number changes
      local view = vim.fn.winsaveview()
      local folded_ref_ids = {}
      local parser = require("fyler.views.finder.parser")
      
      -- Check which ref_ids are currently folded
      for i = 1, vim.fn.line('$') do
        if vim.fn.foldclosed(i) == i then  -- This line is the start of a closed fold
          local line = vim.fn.getline(i)
          local ref_id = parser.parse_ref_id(line)
          if ref_id then
            folded_ref_ids[ref_id] = true
          end
        end
      end
      
      -- Update fold definitions
      vim.cmd("silent! normal! zx")
      
      -- Restore the fold state using ref_ids
      for i = 1, vim.fn.line('$') do
        local line = vim.fn.getline(i)
        local ref_id = parser.parse_ref_id(line)
        if ref_id and folded_ref_ids[ref_id] then
          -- This ref_id should be folded
          if vim.fn.foldclosed(i) == -1 then
            vim.fn.setpos('.', {0, i, 1, 0})
            vim.cmd("silent! normal! zc")
          end
        end
      end
      
      -- Restore view
      vim.fn.winrestview(view)
    end)
  end)
end

return M
