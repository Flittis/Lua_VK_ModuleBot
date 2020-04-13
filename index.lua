vk = require "vkapi"
json = require "dkjson"
local utf8 = require "lua-utf8"
local lfs = require "lfs"

local config = {}
for k, v in pairs(require "config") do if k and v then config[k] = v end end

if not config.accessToken then
    print("[ERROR]\tAccess token in config is not defined")
    return os.exit()
end

vk.init(config.accessToken)

local modules = {}
for entry in lfs.dir("modules") do
  if entry == '.' or entry == '..' then
  elseif entry:sub(-4) == ".lua" then
    print(('[LOG]\tLoading module %q'):format(entry))
    local chunk, err = loadfile("modules/" .. entry)
    if chunk then
      local succ, ret = pcall(chunk, config)
      if succ then
        if type(ret.func) == 'function' then
          print(('[LOG]\tModule %q was loaded successfully'):format(entry))
          table.insert(modules, ret.func)
        else print(('[ERROR]\tModule %q has wrong structure'):format(entry)) end
      else print(('[ERROR]\tRuntime error in module %q: %s'):format(entry, ret)) end
    else print(('[ERROR]\tError loading module %q: %s'):format(entry, err)) end
  else print(("[ERROR]\tFile %q is not .lua file"):format(entry)) end
end

vk:on('message', function(msg)    -- creating callback function
    for i = 1, #modules do modules[i](msg) end
end)

for name, func in pairs(utf8)do if string[name]then string['_' .. name] = string[name];  string[name] = func end end
vk.longpollStart()
