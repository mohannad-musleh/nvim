M = {}

function M.trim(str, char)
  local pattern = '^(' .. char .. '*)(.-)(' .. char .. '*)$'
  return str:gsub(pattern, '%2')
end

---Check if the path is valid and points to a directory
---
---@param path string
---@return boolean
function M.is_valid_directory_path(path)
  local stat = vim.uv.fs_stat(path)
  return stat ~= nil and stat.type == 'directory'
end

---Show a file picker and call the callback wit the selected file path, if the user cancel the selection,
---the callback will be called with `nil`
---
---@param callback fun(param: string|nil): nil
---@param opts? table any additional options to be passed to telescope.builtin.file_files function (e.g. { hidden = true,  prompt_title = 'Pick a file' })
function M.pick_file(callback, opts)
  local is_telescope_installed, _ = pcall(require, 'telescope')
  if not is_telescope_installed then
    vim.api.nvim_err_writeln('`telescope.nvim` plugin must be installed and setup before using `pick_file`.')
    return
  end

  local action_state = require('telescope.actions.state')
  local builtin = require('telescope.builtin')
  local actions = require('telescope.actions')

  opts = vim.tbl_deep_extend('force', (opts or {}), {
    attach_mappings = function(_, map)
      map('i', '<CR>', function(prompt_bufnr)
        -- Get the selected file
        local selection = action_state.get_selected_entry()
        actions.close(prompt_bufnr)

        if selection and selection.path then
          callback(selection.path)
        else
          callback(nil)
        end
      end)

      map('n', '<Esc>', function(prompt_bufnr)
        require('telescope.actions').close(prompt_bufnr)
        callback(nil)
      end)

      map('i', '<C-c>', function(prompt_bufnr)
        require('telescope.actions').close(prompt_bufnr)
        callback(nil)
      end)

      return true
    end,
  })

  builtin.find_files(opts)
end

---Walk a directory and return a flatten table contains the path of all files under it (recursively)
---
---@param dir string
---@return table
function M.dir_flatten_tree(dir)
  local result = {}
  local handle = vim.uv.fs_scandir(dir)

  if not handle then
    return result -- Return an empty table if the directory cannot be scanned
  end

  while true do
    local name, t = vim.uv.fs_scandir_next(handle)
    if not name then
      break -- Exit the loop when there are no more entries
    end

    local path = dir .. '/' .. name
    if t == 'directory' then
      -- Recursively flatten the contents of the directory
      local sub_files = M.dir_flatten_tree(path)
      for _, file in ipairs(sub_files) do
        table.insert(result, file) -- Add each file to the result
      end
    else
      table.insert(result, path) -- Add the full path of the file to the result
    end
  end

  return result
end

---Convert a string to a pattern to be able to use it with `string.match` method
---
---@param s string
---@return string
function M.str_to_pattern(s)
  local pattern = s:gsub('([%.%[%]%(%)%+%-%*%?%^%$])', '%%%1')
  return pattern
end

---Merge two tables and ensure unique values
---
---@param table1 table
---@param table2 table
---@return table
function M.merge_tables_unique(table1, table2)
  local unique_set = {}
  local result = {}

  for _, value in ipairs(table1) do
    if not unique_set[value] then
      unique_set[value] = true
      table.insert(result, value)
    end
  end

  for _, value in ipairs(table2) do
    if not unique_set[value] then
      unique_set[value] = true
      table.insert(result, value)
    end
  end

  return result
end

---Merge the passed table with `vim.g.global_ignore_dirs` and `vim.g.local_ignore_dirs` tables
---@param t table
---@return table
function M.merge_table_with_global_ignores(t)
  if type(vim.g.global_ignore_dirs) == 'table' and #vim.g.global_ignore_dirs > 0 then
    t = M.merge_tables_unique(t, vim.g.global_ignore_dirs)
  end

  if type(vim.g.local_ignore_dirs) == 'table' and #vim.g.local_ignore_dirs > 0 then
    t = M.merge_tables_unique(t, vim.g.local_ignore_dirs)
  end

  return t
end

---Check if the path is a child (directly or indirectly) to one of the directories listed in `directories` table
---
---@param path string path to be checked
---@param directories table<string> list of directories' names to check if the path includes one of them (NOTE: only include the directory name, no `/` needed nor characters escaping)
---@return boolean
function M.is_path_under_dirs(path, directories)
  if not path or path == '' or type(directories) ~= 'table' or #directories < 1 then
    return false
  end

  for _, dir_name in ipairs(directories) do
    local pattern = M.str_to_pattern('/' .. M.trim(dir_name, '/') .. '/')
    if path:match(pattern) then
      return true
    end
  end

  return false
end

---Change all values in a table to string patterns
---
---@param t table<string>
---@return table<string>
function M.str_table_to_patterns(t)
  local result = {}

  for _, s in ipairs(t) do
    table.insert(result, M.str_to_pattern(s))
  end

  return result
end

---Copy current buffer path to the clipboard (`+` reg)
---
---@param bufnr? number the buffer number (by default current buffer)
---@return string|nil # the copied path or nil if can't get the buffer path (non file buffer)
function M.copy_buffer_path(bufnr)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local path = vim.fn.expand(vim.api.nvim_buf_get_name(bufnr))
  -- Check if the buffer has a valid path
  if path == '' then
    print('No valid path for buffer ' .. bufnr)
    return nil
  end

  vim.fn.setreg('+', path)
  return path
end

return M
