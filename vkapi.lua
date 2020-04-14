local cURL = require "cURL"
local json = require "dkjson"
local bit = require "bit32"

local logFile = io.open("vkapi.log", "a")
io.output(logFile)

local vk = {
    token = nil,
    apiUrl = "https://api.vk.com/method/%s?%saccess_token=%s&v=5.69",
    longPollUrl = "https://%s?act=a_check&wait=25&mode=234&key=%s&ts=%s",
    longPollWork = false,
    longPollData = {
        server = nil,
        key = nil,
        ts = nil
    },
    callbacks = {}
}

function vk.init(token) vk.token = token end
function vk.longpollStop() vk.longPollWork = false end
function vk:on(cbtype, cbfunc) self.callbacks[cbtype] = cbfunc end

function vk.longpollStart()
    print("[LOG]\tStarting LongPoll")
    local lpGet = vk.longpollGet()
    if lpGet and lpGet.error then
        print(("[ERROR]\tError occured when getting LongPoll server - %q"):format(lpGet.error))
        vk.longpollStop()
        return vk.longpollStart()
    end
    vk.longPollWork = true

    print("[LOG]\tStarting LongPoll listening")
    while vk.longPollWork do
      vk.longpollListen()
    end
end

function vk.call(method, parameters, notLog)
    if not vk.token then return { error = "Access token is not defined" } end
    local paramstr

    if parameters then for key, value in pairs(parameters) do paramstr = (paramstr and paramstr or "") .. key .. "=" .. value .. "&" end end
    local url = vk.apiUrl:format(method, paramstr or '&', vk.token)
    local response, response_str = '', ''

    cURL.easy{
        url = url,
        httpheader = { "user-agent: npm/VK-Promise" },
        writefunction = function(res) response_str = response_str .. res end
    }:perform():close()
    response = json.decode(response_str, 1, nil)

    print("\n[REQUEST]\t( " .. method .. " " .. (paramstr or "") .. " ) \n[RESPONSE]\t" .. response_str .. "\n")
    if response.error then
        io.write("\n////////////////[ERROR]//////////////// \n[RESPONSE]\t" .. response_str .. "\n////////////////////////////////////////\n")
        return response
    end
    if not notLog then io.write("\n[REQUEST]\t( " .. method .. " " .. (paramstr or "") .. " ) \n[RESPONSE]\t" .. response_str .. "\n") end

    return response.response
end

function vk.longpollListen()
    if not (vk.longPollData.server and vk.longPollData.key and vk.longPollData.ts) then return "One of parameters are not provided."; end

    local response = ''

    local url = vk.longPollUrl:format(vk.longPollData.server, vk.longPollData.key, vk.longPollData.ts)

    cURL.easy{
        url = url,
        httpheader = { "user-agent: npm/VK-Promise" },
        writefunction = function(res) response = response .. res end
    }:perform():close()
    response = json.decode(response, 1, nil)

    if response.failed or response.error then return vk.longpollStart() end

    vk.longPollData.ts = response.ts

    for key, value in pairs(response.updates) do
        local msg = vk.parseLongPoll(value)

        if msg ~= nil then if vk.callbacks['message'] then vk.callbacks['message'](msg) end end
    end
end

function vk.longpollGet()
    print("[LOG]\tGetting LongPoll server")
    local res = vk.call("messages.getLongPollServer", nil, false)
    if res.error then return res end

    vk.longPollData.server = res.server
    vk.longPollData.key = res.key
    vk.longPollData.ts = res.ts
end

function vk.parseLongPoll(data)
    if (data[1] ~= 4) then return nil end

    local msg = {
        id = data[2],
        out = bit.band(data[3], 2) > 0,
        title = data[6],
        body = data[7],
        peer_id = tonumber(data[4]),
        data = data
    }

    if (data[8] and data[8]['attach0']) then
        msg.attachments = {};
        i = 1;

        while (i <= 10) and (data[8]['attach' + i]) do
            table.insert(msg.attachments, data[8]['attach' + i + '_type'] .. data[8]['attach' + i])
            i = i + 1
        end
    end

    if (msg.peer_id > 2e9) then msg.chat_id = msg.peer_id - 2e9 end

    function msg.send(message) vk.call("messages.send", { peer_id = msg.peer_id, message = message }) end
    function msg.reply(message) vk.call("messages.send", { peer_id = msg.peer_id, reply_to = msg.id, message = message }) end
    function msg.forward(peer_id, message) vk.call("messages.send", { peer_id = peer_id, forward_messages = msg.id, message = message or "" }) end
    function msg.edit(message) vk.call("messages.send", { peer_id = msg.peer_id, message_id = msg.id, message = message }) end

    return msg
end

return vk
