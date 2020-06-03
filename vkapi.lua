require 'curl.init'
local bit = require 'bit'

local vk = {
  token = nil,
	userAgent = 'npm/VK-Promise',
  apiVers = '5.107',
  apiUrl = 'https://api.vk.com/method/%s?%saccess_token=%s&v=%s',
  longPollUrl = 'https://%s?act=a_check&wait=25&mode=234&key=%s&ts=%s',
  longPollWork = false,
  longPollData = {
    server = nil,
    key = nil,
    ts = nil
  },
  callbacks = {}
}

function toUri(str) return (type(str) == 'string' and str:_gsub('[%c*%p*%s*]', function(c) return ('%%%02X'):format(c:_byte()) end) or str) end

function vk.init(token) if not token then return false end vk.token = token end
function vk.longpollStop() vk.longPollWork = false end
function vk:on(cbtype, cbfunc) self.callbacks[cbtype] = cbfunc end

function vk.longpollStart()
  vk.longPollWork = false
  print('[LOG]\tStarting LongPoll')
  local lpGet = vk.longpollGet()
  if lpGet and lpGet.error then
    print(('[ERROR]\tError occured when getting LongPoll server - %q'):format(lpGet.error))
    vk.longpollStop()
    return vk.longpollStart()
  end
  vk.longPollWork = true

  print('[LOG]\tStarting LongPoll listening')
  while vk.longPollWork do
    vk.longpollListen()
  end
end

function vk.call(method, parameters, notLog)
  if not vk.token then return { error = 'Access token is not defined' } end
  local paramstr, response, response_str = '', '', ''
  if parameters then for key, value in pairs(parameters) do paramstr = paramstr .. key .. '=' .. toUri(value) .. '&' end end
	local url = vk.apiUrl:format(method, paramstr and paramstr or '&', vk.token, parameters and (parameters.v or vk.apiVers) or vk.apiVers)
	response_str = curl_request(url, vk.userAgent)
  response = json.decode(response_str, 1, nil)

  print('\n[REQUEST]\t( ' .. method .. ' ' .. (paramstr or '') .. ' ) \n[RESPONSE]\t' .. response_str .. '\n')
  if not response or response.error then return response end

  return response.response or response
end

function vk.upload(getUploadUrl, saveUrl, file, settings)
  if not vk.token then return { error = 'Access token is not defined' } end

  local uploadServer = vk.call( getUploadUrl, settings and settings.get )
  if uploadServer.upload_url then
    local uploadRequestStr = curl_post_request(uploadServer.upload_url, vk.userAgent, file)
    print('\n[REQUEST]\t( ' .. uploadServer.upload_url .. ' ) \n[RESPONSE]\t' .. uploadRequestStr or nil .. '\n')

    local uploadRequest = json.decode(uploadRequestStr)

    if uploadRequest and uploadRequest.file then
      local save = vk.call( saveUrl, { file = uploadRequest.file } )

      return save
    end
  end
end

function vk.longpollListen()
  if not (vk.longPollData.server and vk.longPollData.key and vk.longPollData.ts) then return 'One of parameters are not provided.'; end
  local response, response_str = '', ''

	local url = vk.longPollUrl:format(vk.longPollData.server, vk.longPollData.key, vk.longPollData.ts)
	response_str = curl_request(url, vk.userAgent)
  response = json.decode(response_str, 1, nil)
  if response.failed or response.error then return vk.longpollStart() end

  vk.longPollData.ts = response.ts

  for key, value in pairs(response.updates) do

    if value[1] == 2 and bit.band(value[3], 131072) > 0 then
      local delete, event = vk.parseLongPollDelete(value), value

      if delete ~= nil then if vk.callbacks['delete'] then vk.callbacks['delete'](delete) end end
    elseif value[1] == 4 then
      local msg, event = vk.parseLongPollMessage(value), value

      if msg ~= nil then if vk.callbacks['message'] then vk.callbacks['message'](msg) end end
    elseif value[1] == 5 then
      local edit, event = vk.parseLongPollEdit(value), value

      if edit ~= nil then if vk.callbacks['edit'] then vk.callbacks['edit'](edit) end end
    end
  end
end

function vk.longpollGet()
  print('[LOG]\tGetting LongPoll server')
  local res = vk.call('messages.getLongPollServer', nil, false)
  if res.error then return res end

  vk.longPollData.server, vk.longPollData.key, vk.longPollData.ts = res.server, res.key, res.ts
end


function vk.parseLongPollEdit(data)
  if (data[1] ~= 5) then return nil end

  local edit = {
    id = data[2],
    peer_id = tonumber(data[4]),
    user_id = tonumber(data[8].from or data[4]),
    body = data[7],
    data = data
  }

  if (edit.peer_id > 2e9) then edit.chat_id = edit.peer_id - 2e9 end
  return edit
end

function vk.parseLongPollDelete(data)
  if data[1] ~= 2 and bit.band(data[3], 131072) <= 0 then return nil end

  local delete = {
    id = data[2],
    peer_id = tonumber(data[4]),
    data = data
  }

  if (delete.peer_id > 2e9) then delete.chat_id = delete.peer_id - 2e9 end
  return delete
end

local msg_mt = {
  send = function(msg, txtbody, dont_parse_links, disable_mentions) vk.call('messages.send', { peer_id = msg.peer_id, message = txtbody, random_id = 0, dont_parse_links = dont_parse_links and '1' or '0', disable_mentions = disable_mentions and '1' or '0' }) end,
  delete = function(msg, forAll) vk.call('messages.delete', { delete_for_all = forAll and '1' or '0', message_ids = msg.id }) end,
  sendSticker = function(msg, stickerid) vk.call('messages.send', { peer_id = msg.peer_id, sticker_id = stickerid, random_id = 0 }) end,
  reply = function(msg, txtbody) vk.call('messages.send', { peer_id = msg.peer_id, reply_to = msg.id, message = txtbody, random_id = 0 }) end,
  forward = function(msg, peer_id, txtbody) vk.call('messages.send', { peer_id = peer_id, forward_messages = msg.id, message = txtbody or '', random_id = 0 }) end,
  edit = function(msg, txtbody) vk.call('messages.edit', { peer_id = msg.peer_id, message_id = msg.id, message = txtbody }) end
}
msg_mt.__index = msg_mt

function vk.parseLongPollMessage(data)
  if (data[1] ~= 4) then return nil end

  local msg = setmetatable({
    id = data[2],
    out = bit.band(data[3], 2) > 0,
    title = data[6],
    body = data[7],
    peer_id = tonumber(data[4]),
    user_id = tonumber(data[8].from or data[4]),
    data = data
  }, msg_mt)

  if (data[8] and data[8]['attach1']) then
    msg.attachments, i = {}, 1;

    while (i <= 10) and (data[8]['attach' .. i]) do
      table.insert(msg.attachments, data[8]['attach' .. i .. '_type'] .. data[8]['attach' .. i])

      if(data[8]['attachments']) then
        local attach = json.decode(data[8]['attachments'], 1, nil)[i]

        if data[8]['attach' .. i .. '_type'] == 'sticker' then
            msg.sticker = {}

            msg.sticker.id = attach['sticker']['sticker_id']
            msg.sticker.img128 = attach['sticker']['images'][2]['url']
            msg.sticker.img256 = attach['sticker']['images'][3]['url']
            msg.sticker.img512 = attach['sticker']['images'][5]['url']
        elseif data[8]['attach' .. i .. '_kind'] == 'audiomsg' then
            msg.audiomsg = {}

            msg.audiomsg.id = attach['audio_message']['id']
            msg.audiomsg.owner_id = attach['audio_message']['owner_id']
            msg.audiomsg.link_mp3 = attach['audio_message']['link_mp3']
            msg.audiomsg.link_ogg = attach['audio_message']['link_ogg']
        end
      end

      i = i + 1
    end
  end

  if (msg.peer_id > 2e9) then msg.chat_id = msg.peer_id - 2e9 end
  return msg
end

return vk
