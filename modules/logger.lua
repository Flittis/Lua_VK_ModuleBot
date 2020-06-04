local config = ...
local logTrigger = config.logTrigger or addToConfig('logTrigger', '!лог')
local logAddChat = config.logAddChat or addToConfig('logAddChat', '!логчат')
local logMaxRecords = config.logMaxRecords or addToConfig('logMaxRecords', 15)
local logChats = config.logChats or addToConfig('logChats', {})

local obj, logs = {}, {}
local

function isInArray(a, v) for i = 1, #a do if a[i] == v then return i end end return false end
function includes(a, v)  for i = 1, #a do if v:find(a[i]) then return true end end return false end

function findMessageById(chat, id)
  if not logs[chat] then return end

  for i = 1, #logs[chat] do
    if logs[chat][i].message_id == id then return i end
  end

  return false
end

function obj.func(msg)
  if isInArray(logChats, msg.chat_id) and logs[msg.chat_id] and #logs[msg.chat_id] > logMaxRecords then
    while(#logs[msg.chat_id] > logMaxRecords) do
      table.remove(logs[msg.chat_id], 1)
    end
  end

  if not msg.out and isInArray(logChats, msg.chat_id) and not msg.body:lower():find('^лог%s*:') then
    print(json.encode(msg.data))

    local logObj = { message_id = msg.id, user_id = msg.user_id, is_deleted = false, is_edited = false, body = msg.body }

    if msg.sticker then logObj['attachments'] = msg.sticker.img512
    elseif msg.audiomsg then logObj['attachments'] = msg.audiomsg.link_ogg
    elseif msg.attachments then
      local res = vk.call('messages.getById', { message_ids = msg.id })
      local thisAttachments = {}

      if res.items[1] and res.items[1].attachments then
        local thisAttach = res.items[1].attachments

        for i = 1, #thisAttach do
          local type = thisAttach[i]['type']
          local owner_id, id, access_key = thisAttach[i][type]['owner_id'], thisAttach[i][type]['id'], thisAttach[i][type]['access_key']

          if type ~= 'photo' then thisAttachments[i] = 'https://vk.com/' .. type .. (owner_id and owner_id .. (id and '_' .. id .. (access_key and '_' .. access_key or '') or '') or '')
          else thisAttachments[i] = thisAttach[i][type]['sizes'][#thisAttach[i][type]['sizes']].url end
        end

        logObj['attachments'] = table.concat(thisAttachments, ', ')
      end
    end

    if not logs[msg.chat_id] then logs[msg.chat_id] = {} end

    table.insert(logs[msg.chat_id], logObj)
  end

  if msg.out and msg.body:lower() == logAddChat then
    local check = isInArray(logChats, msg.chat_id)

    if check then table.remove(logChats, check)
    else table.insert(logChats, msg.chat_id) end

    addToConfig('logChats', logChats)
    saveConfig()

    return msg:edit('Чат ' .. msg.chat_id .. ' был ' .. (check and 'удален' or 'добавлен') .. '.')
  elseif msg.out and isInArray(logChats, msg.chat_id) and logs[msg.chat_id] and msg.body:lower():find('^' .. logTrigger) then
    msg:delete(true)

    local logStr, logUsers = 'Лог:', {}

    for i = 1, #logs[msg.chat_id] do
      local val = logs[msg.chat_id][i]

      if val and val.message_id then
        table.insert(logUsers, val.user_id)
        local thisLogStr, thisMsgStr = '@id' .. val.user_id .. ': %s', val.body .. (val.attachments and '\n[Вложения] ' .. val.attachments or '')

        if val.is_edited then thisMsgStr = '[edited]\n' .. thisMsgStr end
        if val.is_deleted then thisMsgStr = '[deleted] ' .. thisMsgStr end

        logStr = logStr .. '\n' .. thisLogStr:format(thisMsgStr)
      end
    end

    while(#logs[msg.chat_id] > 0) do
      table.remove(logs[msg.chat_id], 1)
    end

    local usersResponse = vk.call('users.get', { user_ids = table.concat(logUsers, ',') })

    for _, val in ipairs(usersResponse) do
      logStr = logStr:gsub('@id' .. val.id, '@id' .. val.id .. ' (' .. val.first_name .. ')')
    end

    msg:send(logStr, 1, 1)
  end
end

function obj.delete(delete)
  if not isInArray(logChats, delete.chat_id) then return end

  local find = findMessageById(delete.chat_id, delete.id)

  if find then
    logs[delete.chat_id][find]['is_deleted'] = true
  end
end

function obj.edit(edit)
  if not isInArray(logChats, edit.chat_id) then return end

  local find = findMessageById(edit.chat_id, edit.id)

  if find then
    logs[edit.chat_id][find]['is_edited'] = true
    logs[edit.chat_id][find]['body'] = logs[edit.chat_id][find]['body'] .. ' -> ' .. edit.body
  end
end

return obj

    -- if msg.sticker then print(msg.sticker.img512) end
    -- if msg.audiomsg then print(msg.audiomsg.link_ogg) end
