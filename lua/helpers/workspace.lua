local M = {}

--- Checks if the current workspace is a Frontend project by looking for a `package.json`.
--- Optionally verifies if a list of specific dependencies are defined.
--- Works even if no file buffer is open (gracefully falls back to the current working directory).
---
---@param required_packages? string[] (Optional) List of package names to check for in dependencies or devDependencies.
---@return boolean # True if package.json exists and contains all required packages, false otherwise.
function M.is_fe_project(required_packages)
  -- 1. Find package.json starting from the current buffer
  local root = vim.fs.root(0, 'package.json')

  -- If buffer-based look up fails, safely fallback to current working directory
  if not root then
    local cwd = vim.uv.cwd()
    if cwd then root = vim.fs.root(cwd, 'package.json') end
  end

  -- If package.json cannot be found anywhere in the path hierarchy, it's not our FE project
  if not root then return false end

  -- 2. If the required_packages table is empty or nil, just knowing package.json exists is enough
  if not required_packages or #required_packages == 0 then return true end

  -- 3. Read the package.json file
  local package_json_path = vim.fs.joinpath(root, 'package.json')
  local file = io.open(package_json_path, 'r')
  if not file then return false end
  local content = file:read '*a'
  file:close()

  -- 4. Safely parse the JSON content
  local ok, json = pcall(vim.json.decode, content)
  if not ok or type(json) ~= 'table' then return false end

  local deps = json.dependencies or {}
  local dev_deps = json.devDependencies or {}

  -- 5. Verify that ALL required packages are present in either dependencies or devDependencies
  for _, pkg in ipairs(required_packages) do
    if deps[pkg] == nil and dev_deps[pkg] == nil then
      return false -- Return false early if any single required package is missing
    end
  end

  return true
end

return M
