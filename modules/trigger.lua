local config = ...

if not config.stickerReply then addToConfig('stickerReply', nil, {}) end

local stickerTriggerWords = config.stickerReply.words or addToConfig('stickerReply', 'words', {'ping', 'пинг'})
local stickerTriggerChats = config.stickerReply.chats or addToConfig('stickerReply', 'chats', {1, 2, 3})
local stickerTriggerStickers = config.stickerReply.stickers or addToConfig('stickerReply', 'stickers', {1, 2, 3})
local stickerTimeoutTime = config.stickerReply.timeout or addToConfig('stickerReply', 'timeout', 5)
local stickerAddChat = config.stickerReply.addChatTrigger or addToConfig('stickerReply', 'addChatTrigger', '!chat')
local stickerAddSticker = config.stickerReply.addStickerTrigger or addToConfig('stickerReply', 'addStickerTrigger', '!sticker')

local obj, timeout = {}, {}

math.randomseed(os.time())
local function isInArray(a, v) for i = 1, #a do if a[i] == v then return i end end return false end
local function includes(a, v)  for i = 1, #a do if v:find(a[i]) then return true end end return false end

-- Main function

function obj.func(msg)
  if(msg.body:lower() == stickerAddChat) then
    local check = isInArray(stickerTriggerChats, msg.chat_id)
    if check then table.remove(stickerTriggerChats, check) else table.insert(stickerTriggerChats, msg.chat_id) end

    addToConfig('stickerReply', 'chats', stickerTriggerChats)
    saveConfig()

    return msg:edit('Чат ' .. msg.chat_id .. ' был ' .. (check and 'удален' or 'добавлен') .. '.')
  elseif(msg.body:lower():find('^' .. stickerAddSticker)) then
    local nums, toAdd, toDel = msg.body:match('^' .. stickerAddSticker .. '%s+(%A+)') or '', {}, {}

    if not nums or nums == '' then
      local res = vk.call('messages.getById', { message_ids = msg.id })

      if res.items and res.items[1] then
        if res.items[1].reply_message then
          if res.items[1].reply_message.attachments[1].type == 'sticker' then nums = nums .. ' ' .. res.items[1].reply_message.attachments[1].sticker.sticker_id end
        elseif res.items[1].fwd_messages then
          for k, v in pairs(res.items[1].fwd_messages) do
            if v.attachments[1].type == 'sticker' then nums = nums .. ' ' .. v.attachments[1].sticker.sticker_id end
          end
        end
      end
    end
    nums:gsub("%d+", function(c) local check = isInArray(stickerTriggerStickers, tonumber(c)) table.insert(check and toDel or toAdd, c) end)

    if #toAdd > 0 then for i,v in pairs(toAdd) do table.insert(stickerTriggerStickers, tonumber(v)) end end
    if #toDel > 0 then for i,v in pairs(toDel) do table.remove(stickerTriggerStickers, isInArray(stickerTriggerStickers, tonumber(v))) end end

    addToConfig('stickerReply', 'stickers', stickerTriggerStickers)
    saveConfig()

    return #toAdd + #toDel > 0 and msg:edit('Стикеры ' .. (#toAdd > 0 and 'добавлены: ' .. table.concat(toAdd, ', ') .. '\n' or '') .. (#toDel > 0 and 'удалены: ' .. table.concat(toDel, ', ') or '')) or false
  end

  if(includes(stickerTriggerWords, msg.body:lower()) and (not timeout[msg.peer_id] or os.time() > timeout[msg.peer_id]) and msg.out == false and (not stickerTriggerChats[1] or isInArray(stickerTriggerChats, msg.chat_id))) then
    msg:sendSticker(stickerTriggerStickers[math.random(1, #stickerTriggerStickers)])
    timeout[msg.peer_id] = os.time() + (stickerTimeoutTime * 60)
  end
end

return obj
