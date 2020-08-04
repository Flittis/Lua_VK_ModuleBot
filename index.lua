-- loading libraries
vk = require 'vkapi'
json = require 'dkjson'
local utf8 = require 'lua-utf8'

local config = {}	-- config table
local modules = { message = {}, delete = {}, edit = {} }  -- modules table

--[[////////////////////////
			Modules Functions
	////////////////////////]]

-- function to parse module
function loadModule(name)
	print(('[LOG]\tLoading module %q'):format(name))

	-- loading module file
	local chunk, err = loadfile('modules/' .. name)

	-- if file loaded - continue
	if chunk then
		local succ, ret = pcall(chunk, config)

		-- if no errors - continue
		if succ then
			if not ret.func and not ret.delete and not ret.edit then return print(('[ERROR]\tModule %q has wrong structure'):format(name)) end

			-- if modules has right structure insert module function in table
			if type(ret.func) == 'function' then table.insert(modules.message, ret.func) end
			if type(ret.delete) == 'function' then table.insert(modules.delete, ret.delete) end
			if type(ret.edit) == 'function' then table.insert(modules.edit, ret.edit) end

			print(('[LOG]\tModule %q was loaded successfully'):format(name))
		else print(('[ERROR]\tRuntime error in module %q: %s'):format(name, ret)) end
	else print(('[ERROR]\tError loading module %q: %s'):format(name, err)) end
end

-- function to load modules
function loadModules()
	print(('[LOG]\tLoading modules...'))

	-- opening modules directory
  local handle = io.popen('ls modules', 'r')

	-- if directory exists
  if handle then

		-- try load every file from 'modules' folder
  	for entry in handle:lines() do

			-- skip system files
  		if entry ~= '.' and entry ~= '..' then

				-- if file has extension `.lua` – try to load
  			if entry:sub(-4) == '.lua' then loadModule(entry)
  			else print(('[ERROR]\tFile %q is not .lua file'):format(entry)) end
  		end
  	end

		-- closing directory
  	handle:close()
  else print('[ERROR]\tFailed to open modules directory') end
end

--[[////////////////////////
			Config Functions
	////////////////////////]]


-- function to parse value to string
function toStringValue(v)
	if type(v) == 'string' then return "'" .. v .. "'"
	elseif type(v) == 'table' then
		local str, ttype = '', 'array'
		for key, val in pairs(v) do
			if type(key) == 'number' then str = str .. toStringValue(val) .. ((key < #v) and ', ' or '')
			elseif type(key) == 'string' then
				str = str .. '		' .. key .. ' = ' .. toStringValue(val) .. ',\n'
				ttype = 'obj'
			end
		end
		return '{' .. (ttype == 'obj' and '\n' or '') .. str .. (ttype == 'obj' and '	' or '') ..  '}'
	else return tostring(v) end
end

-- function for appending value to config
function addToConfig(key, key2, value)
	if key2 then config[key][key2] = value
	elseif not key2 then config[key] = value end

	return value
end

-- function to load config
function loadConfig()
  local chunk, err = loadfile('config.lua')

	if err then print(err) end

  if chunk then
		local succ, ret = pcall(chunk)
		if succ then config = ret end
	else config.accessToken = '' end
end

-- function to save config
function saveConfig()
    local f = io.open('config.lua', 'w')
    f:write('return {\n')
    for k, v in pairs(config) do f:write('  ', k, ' = ', toStringValue(v), ',\n') end
    f:write('}')
    f:close()
end


-- loading config, modules and then saving config
loadConfig()
loadModules()
saveConfig()

-- if access token in config file is not exist – send error and crash script
if not config.accessToken or config.accessToken == '' then
  print('[ERROR]\tPlease fill `config.lua` file in script directory')
  return os.exit()
end

--[[////////////////////////
			Main Functions
	////////////////////////]]

-- init vk-api library
vk.init(config.accessToken)

-- callback function for new messages
vk:on('message', function(msg) for i = 1, #modules.message do modules.message[i](msg) end end)

-- callback function for deleting messages
vk:on('delete', function(delete) for i = 1, #modules.delete do modules.delete[i](delete) end end)

-- callback function for editing messages
vk:on('edit', function(edit) for i = 1, #modules.edit do modules.edit[i](edit) end end)

-- converting string function to utf-8
for name, func in pairs(utf8) do if string[name] then string['_' .. name] = string[name];  string[name] = func end end

-- starting longpoll
vk.longpollStart()
