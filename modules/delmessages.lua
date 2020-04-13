local config = ...
local deleteTrigger, deleteTriggerAll, deleteEditTo = config.deleteTrigger or "ой", config.deleteTriggerAll or "/delall", config.deleteEditTo or "ᅠ"

local obj = {}

function obj.func(msg)
    if(msg.out and (msg.body:lower():find('^' .. deleteTrigger ..'([%-0-9]*)$') or msg.body:lower():find('^' .. deleteTriggerAll ..'([%-0-9]*)$'))) then          -- checking if message is equal to trigger
        local res = vk.call('messages.getHistory', { peer_id = msg.peer_id, count = 150 }, true)        -- getting messages history in this chat
        if res.items == nil or res.count == 0 then return end                                           -- if anything wrong or chat is empty - return
        local num

        if msg.body:lower():find('^' .. deleteTriggerAll .. '([%-0-9]*)$') then num = 150
        else num = msg.body:lower():match('^' .. deleteTrigger .. '([%-0-9]+)$') end

        if num == '-' then num = -1 end
        num = tonumber(num) or 1

        local isEdit = num < 0 and "true" or "false"                                                  -- checking if we must to edit message before deleting
        if num < 0 then num = num * -1 end

        local idsToDel, i = {tonumber(msg.id)}, 1                                                       -- creating table of messages which would be deleted

        while(#idsToDel <= num + 1 and i <= #res.items) do                                              -- loop for getting ids of messages which would be deleted
            if res.items[i].out == 1 then table.insert(idsToDel, res.items[i].id) end                   -- if message is out - adding to table
            i = i + 1                                                                                   -- increment integer
        end

        idsToDel = json.encode(idsToDel):gsub("{", ""):gsub("}", "")                                    -- convert table to string and removing brakets

        if isEdit == "true" then                                                                        -- if we must to edit message
            local code = [[ var arr = %s, i = 1; while(i < arr.length) { if(arr[i] != %s) API.messages.edit({ peer_id: %s, message_id: arr[i], message: "%s" }); i = i + 1; } ]] -- code template for execute to edit messages
            code = code:format(idsToDel, msg.id, msg.peer_id, deleteEditTo)                                   -- formating code with variables
            code = code:_gsub('.', function(c) return ('%%%02X'):format(c:_byte()) end)                 -- convert code to uri

            vk.call('execute', { code = code })                                                         -- calling execute with this code
        end

        vk.call('messages.delete', { delete_for_all = '1', message_ids = idsToDel })                    -- calling deleting of messages
    end                                                                                              -- starting longpoll listening
end

return obj
