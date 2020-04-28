local config = ...
local obj, giveaways = {}, {}
local giveawayDefWord, giveawayStartWord, giveawayStop, giveawayDefTime, giveawayMinUsers = string.lower(config.giveawayDefWord or 'ку'), string.lower(config.giveawayStartWord or '!розыгрыш'), string.lower(config.giveawayStop or '!stop'), config.giveawayDefTime or 5, config.giveawayMinUsers or 1
local phrases = {
    giveawayStart = 'Начинается розыгрыш! Чтобы принять участие, напишите: \'%s\'. Заканчиваем через %d %s!',
    giveawayUsers = '\n %d %s: %s',
    giveawayEnd = 'Розыгрыш окончен! И из %d %s, побеждает @id%d (%s), поздравляем!',
    giveawayNoUsers = 'В розыгрыше никто не участвовал.',
    giveawayTooFewUsers = 'В розыгрыше приняли участие слишком мало игроков!',
    declensions = {
        time = {'минуту', 'минуты', 'минут'},
        users = {'участник', 'участника', 'участников'}
    }
}

math.randomseed(os.time())
function declOfNum(number, titles) return titles[ ((number % 100 > 4 and number % 100 < 20) and 2 or ({2, 0, 1, 1, 1, 2})[((number % 10 < 5) and number % 10 or 5) + 1]) + 1 ] end
function toUri(str) return str:_gsub('.', function(c) return ('%%%02X'):format(c:_byte()) end) end
function findWinner(gvObj)
    local ids, count, msgTemplate = {}, 0, ''
    for k, v in pairs(gvObj.users) do table.insert(ids, k) count = count + 1 end

    print(ids[1])
    giveaways[gvObj.peer_id] = nil

    if not gvObj.users or count == 0 then msgTemplate = phrases.giveawayNoUsers
    elseif count < giveawayMinUsers then msgTemplate = phrases.giveawayTooFewUsers
    else
      local winnerId = ids[math.random(1, #ids)]
      msgTemplate = phrases.giveawayEnd:format(count, declOfNum(count, phrases.declensions.users), winnerId, gvObj.users[winnerId])
    end

    vk.call('messages.send', { peer_id = gvObj.peer_id, message = toUri(msgTemplate) })
end

function obj.func(msg)
  for k, v in pairs(giveaways) do if os.time() > v.end_time then findWinner(v) end end

  if msg.out then
      if msg.body:lower():find('^' .. giveawayStartWord) then
          local time, str = tonumber(msg.body:match('^' .. giveawayStartWord .. '%s*(%d+)%s*') or giveawayDefTime), msg.body:match('^' .. giveawayStartWord .. '%s*%d*%s*(.+)') or giveawayDefWord

          msg:edit(toUri(phrases.giveawayStart:format(str, time, declOfNum(time, phrases.declensions.time))))
          giveaways[msg.peer_id] = { trigger = str, time = time, end_time = os.time() + (time * 60), peer_id = msg.peer_id, msg_id = msg.id, users = { } }
      end
  elseif giveaways[msg.peer_id] and msg.body:lower() == giveaways[msg.peer_id].trigger:lower() and not giveaways[msg.peer_id].users[msg.user_id] then
      local res = vk.call('users.get', { user_ids = msg.user_id })
      giveaways[msg.peer_id].users[msg.user_id] = res[1].first_name

      local gvObj, usersTemplate = giveaways[msg.peer_id], {}
      for k, v in pairs(gvObj.users) do table.insert(usersTemplate, '@id' .. k .. ' (' .. v .. ')') end

      local msgTemplate = phrases.giveawayStart:format(gvObj.trigger, gvObj.time, declOfNum(gvObj.time, phrases.declensions.time)) .. phrases.giveawayUsers:format(#usersTemplate, declOfNum(#usersTemplate, phrases.declensions.users), table.concat(usersTemplate, ' ,'))

      vk.call('messages.edit', { peer_id = msg.peer_id, message_id = gvObj.msg_id, message = toUri(msgTemplate) })
  end
end



return obj
