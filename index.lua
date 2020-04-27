vk = require "vkapi"
json = require "dkjson"
local utf8 = require "lua-utf8"
local lfs = require "lfs"
local config = require "config"

if not config.accessToken then                              -- if access token in config file is not exist
  print("[ERROR]\tAccess token in config is not defined")
  return os.exit()                                          -- exit script
end

vk.init(config.accessToken)                                 -- init vkapi library

local modules = {}                                                                    -- module table
for entry in lfs.dir("modules") do                                                    -- for every file in "modules" folder
  if entry == '.' or entry == '..' then                                               -- skip system files
  elseif entry:sub(-4) == ".lua" then                                                 -- if file ends with .lua – loading
    print(('[LOG]\tLoading module %q'):format(entry))
    local chunk, err = loadfile("modules/" .. entry)                                  -- loading module file
    if chunk then                                                                     -- if file loaded - continue
      local succ, ret = pcall(chunk, config)                                          -- checking file for errors
      if succ then                                                                    -- if no errors - continue
        if type(ret.func) == 'function' then                                          -- if module has right structure
          print(('[LOG]\tModule %q was loaded successfully'):format(entry))
          table.insert(modules, ret.func)                                             -- insert module function in table
        else print(('[ERROR]\tModule %q has wrong structure'):format(entry)) end
      else print(('[ERROR]\tRuntime error in module %q: %s'):format(entry, ret)) end
    else print(('[ERROR]\tError loading module %q: %s'):format(entry, err)) end
  else print(("[ERROR]\tFile %q is not .lua file"):format(entry)) end
end

vk:on('message', function(msg)                                        -- creating callback function
  for i = 1, #modules do modules[i](msg) end                          -- call every module from table
end)

for name, func in pairs(utf8)do if string[name]then string['_' .. name] = string[name];  string[name] = func end end    -- converting string function to utf-8
vk.longpollStart()                                                                                                      -- starting longpoll
