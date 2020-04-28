local config = ...
local stickerTriggerWords, stickerTriggerChats, stickerTriggerStickers, stickersTimeoutTime = config.stickerTriggerWords or {'ping'}, config.stickerTriggerChats or {}, config.stickerTriggerStickers or {1}, config.stickerTriggerTime or 5
local timeout = {}

local obj = {}

math.randomseed(os.time())
function isInArray(a, v) for i = 1, #a do if a[i] == v then return true end end return false end
function includes(a, v)  for i = 1, #a do  if v:find(a[i]) then return true end end return false end

function obj.func(msg)
  if(includes(stickerTriggerWords, msg.body:lower()) and (not timeout[msg.peer_id] or os.time() > timeout[msg.peer_id]) and msg.out == false and (not stickerTriggerChats[1] or isInArray(stickerTriggerChats, msg.chat_id))) then
    msg:sendSticker(stickerTriggerStickers[math.random(1, #stickerTriggerStickers)])
    timeout[msg.peer_id] = os.time() + (stickersTimeoutTime * 60)
  end
end

return obj
