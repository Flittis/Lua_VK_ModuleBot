vk = require 'vkapi'
json = require 'dkjson'
local utf8 = require 'lua-utf8'
local config = require 'config'

if not config.accessToken then                              -- if access token in config file is not exist
  print('[ERROR]\tAccess token in config is not defined')
  return os.exit()                                          -- exit script
end

vk.init(config.accessToken)                                 -- init vkapi library

local modules = {}                                                                    -- module table

function loadModule(name)
	print(('[LOG]\tLoading module %q'):format(name))
	local chunk, err = loadfile('modules/' .. name)                                   -- loading module file
	if chunk then                                                                     -- if file loaded - continue
		local succ, ret = pcall(chunk, config)                                          -- checking file for errors
		if succ then                                                                    -- if no errors - continue
			if type(ret.func) == 'function' then                                          -- if module has right structure
				print(('[LOG]\tModule %q was loaded successfully'):format(name))
				table.insert(modules, ret.func)                                             -- insert module function in table
			else print(('[ERROR]\tModule %q has wrong structure'):format(name)) end
		else print(('[ERROR]\tRuntime error in module %q: %s'):format(name, ret)) end
	else print(('[ERROR]\tError loading module %q: %s'):format(name, err)) end
end

local handle = io.popen('ls modules', 'r')                                          -- open modules directory
if handle then
	for entry in handle:lines()do                                                     -- for every file in 'modules' folder
		if entry ~= '.' and entry ~= '..' then                                          -- skip system files
			if entry:sub(-4) == '.lua' then                                               -- if file ends with .lua – loading
				loadModule(entry)
			else print(('[ERROR]\tFile %q is not .lua file'):format(entry)) end
		end
	end
	handle:close()
else print('[ERROR]\tFailed to open modules directory') end

vk:on('message', function(msg)                                        -- creating callback function
  for i = 1, #modules do modules[i](msg) end                          -- call every module from table
end)

for name, func in pairs(utf8)do if string[name]then string['_' .. name] = string[name];  string[name] = func end end    -- converting string function to utf-8
vk.longpollStart()                                                                                                      -- starting longpoll
