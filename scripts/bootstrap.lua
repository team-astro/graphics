local util   = require "tundra.util"

function add_package_paths(paths)
  for _, dir in util.nil_ipairs(paths) do
    -- Make sure dir is sane and ends with a slash
    dir = dir:gsub("[/\\]", SEP):gsub("[/\\]$", "")
    local expr = dir .. SEP .. "?.lua"

    -- Add user toolset dir first so they can override builtin scripts.
    package.path = expr .. ";" .. package.path
  end
end

local scriptDirs = {
  "scripts",
  "../astro/scripts",
}
add_package_paths(scriptDirs)
