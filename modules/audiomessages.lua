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
  			if entry:sub(-4) == '.ogg' then table.insert(audios, entry:sub(1, -5)) end
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
  local file = io.open('./audios/temp', 'w')
  if file then
    for k,v in pairs(audio_cache) do file:write(k .. ':' .. v .. '\n') end
    file:close()

    os.rename('./audios/temp', './audios/audio_cache.txt')
  end
end

loadAudios()
loadAudioConfig()

-- Main function

function obj.func(msg)
  local inArray, inObject = isInArray(audios, msg.body:lower():sub(2)), isInObject(audio_cache, msg.body:lower():sub(2))

  if msg.out and msg.body:find('^!.+') and (inArray or inObject) then
    msg:delete(true)

    local doc, filename = '', msg.body:lower():sub(2)

    if inObject then doc = audio_cache[filename]
    else
      local res = vk.upload(
      'docs.getMessagesUploadServer',
      'docs.save',
      './audios/' .. filename .. '.ogg',
        {
          get = {
            type = 'audio_message',
            peer_id = msg.peer_id
          }
        }
      )

      print('\n' .. json.encode(res) .. '\n')

      if not res or res.error then return
      else
        doc = 'doc' .. res.audio_message.owner_id .. '_' .. res.audio_message.id
        audio_cache[filename] = doc
        saveAudioConfig()
      end
    end

    vk.call('messages.send', { peer_id = msg.peer_id, attachment = doc, random_id = 0 })
  end

  if msg.out and msg.body:lower():find('^' .. audioAdd .. '%s+.+') then
    local res, name = vk.call('messages.getById', { message_ids = msg.id }), msg.body:lower():match('^' .. audioAdd .. '%s+(.+)')
    msg:delete(true)

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
