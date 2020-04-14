local config = ...
local stickerTriggerWords, stickerTriggerChats, stickerTriggerStickers, stickersTimeoutTime = config.stickerTriggerWords or {'ping'}, config.stickerTriggerChats or {}, config.stickerTriggerStickers or {1}, config.stickerTriggerTime or 5
local timeout = {}

local obj = {}

math.randomseed(os.time())
function isInArray(a, v) for i = 1, #a do if a[i] == v then return true end end return false end
function includes(a, v) 
    for i = 1, #a do 
        if v:find(a[i]) then return true end
    end 
    return false 
end

function obj.func(msg)    -- creating callback function
    if(timeout[msg.peer_id] and os.time() > timeout[msg.peer_id]) then timeout[msg.peer_id] = nil end

    if(timeout[msg.peer_id] == nil and msg.out == false and includes(stickerTriggerWords, msg.body:lower()) and (not stickerTriggerChats[1] or isInArray(stickerTriggerChats, msg.chat_id))) then
        vk.call('messages.send', { peer_id = msg.peer_id, sticker_id = stickerTriggerStickers[math.random(1, #stickerTriggerStickers)] })

        timeout[msg.peer_id] = os.time() + (timeoutTime * 60)
    end
end

return obj
