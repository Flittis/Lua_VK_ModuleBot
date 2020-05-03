local config = ...
local obj, audios, audio_cache = {}, {}, {}
local audioAdd = config.audioAdd or addToConfig('audioAdd', '!голосовое')

function isInArray(a, v) for i = 1, #a do if a[i] == v then return i end end return false end
function isInObject(t, v) for k, _ in pairs(t) do if k == v then return true end end return false end

-- Loading Audios

function loadAudios()
  local handle = io.popen('ls audios', 'r')
  if handle then
  	for entry in handle:lines() do
  		if entry ~= '.' and entry ~= '..' then
  			if entry:sub(-4) == '.ogg' then table.insert(audios, entry:sub(1, -5)) print(entry:sub(1, -5)) end
  		end
  	end
  	handle:close()
  else print('[ERROR]\tFailed to open audios directory') end
end

function loadAudioConfig()
  local file = io.open('./audios/audio_cache.txt', 'rw')
  if file then
    for line in file:lines() do
      local k, v = line:match('(.+):(.+)')
      audio_cache[k] = v
    end
    file:close()
  end
end

function saveAudioConfig()
  local file = io.open('./audios/audio_cache.txt', 'w')
  if file then for k,v in pairs(audio_cache) do file:write(k .. ':' .. v .. '\n') end end
  file:close()
end

loadAudios()
loadAudioConfig()

-- Main function

function obj.func(msg)
  local inArray, inObject = isInArray(audios, msg.body:lower():sub(2)), isInObject(audio_cache, msg.body:lower():sub(2))

  if msg.out and (inArray or inObject) then
    msg:delete(true)

    local doc = ''

    if inObject then doc = audio_cache[msg.body:lower():sub(2)]
    else
      local res = vk.upload('docs.getMessagesUploadServer', 'docs.save', './audios/' .. msg.body:lower():sub(2) .. '.ogg', {get = { type = 'audio_message', peer_id = msg.peer_id }})

      if not res or res.error then return
      else
        doc = 'doc' .. res[1].owner_id .. '_' .. res[1].id .. (res[1].access_key and '_' .. res[1].access_keyor '')
        audio_cache[msg.body:lower():sub(2)] = doc
        saveAudioConfig()
      end
    end

    vk.call('messages.send', { peer_id = msg.peer_id, attachment = doc })
  end

  if msg.out and msg.body:lower():find('^' .. audioAdd .. '%s+.+') then
    local res, name = vk.call('messages.getById', { message_ids = msg.id }), msg.body:lower():match('^' .. audioAdd .. '%s+(.+)')

    if res.items[1] and res.items[1].fwd_messages and res.items[1].fwd_messages[1].attachments then
      local attach = res.items[1].fwd_messages[1].attachments[1]

      if attach and attach.type == 'doc' and attach.doc.preview and attach.doc.preview.audio_msg then
        audio_cache[name] = 'doc' .. attach.doc.owner_id .. '_' .. attach.doc.id .. '_' .. attach.doc.access_key
        saveAudioConfig()
      end
    end
  end
end

return obj
