local config = ...
local giveawayDefWord = string.lower(config.giveawayDefWord or addToConfig('giveawayDefWord', 'Ку'))
local giveawayStartWord = string.lower(config.giveawayStartWord or addToConfig('giveawayStartWord', '!розыгрыш'))
local giveawayStop = string.lower(config.giveawayStop or addToConfig('giveawayStop', '!stop'))
local giveawayDefTime = config.giveawayDefTime or addToConfig('giveawayDefTime', 5)
local giveawayMinUsers = config.giveawayMinUsers or addToConfig('giveawayMinUsers', 2)

math.randomseed(os.time())
local obj, giveaways = {}, {}
local phrases = {
    giveawayStart = 'Начинается розыгрыш! Чтобы принять участие, напишите: \'%s\'. Заканчиваем через %s!',
    giveawayUsers = '\n %d %s: %s',
    giveawayEnd = 'Розыгрыш окончен! И из %d %s, побеждает @id%d (%s), поздравляем!',
    giveawayNoUsers = 'В розыгрыше никто не участвовал.',
    giveawayTooFewUsers = 'В розыгрыше приняли участие слишком мало игроков!',
    declensions = {
        minutes = {'минуту', 'минуты', 'минут'},
        seconds = {'секунду', 'секунды', 'секунд'},
        hours = {'час', 'часа', 'часов'},
        users = {'участник', 'участника', 'участников'}
    }
}

-- Additional functions

function declOfNum(number, titles) return titles[ ((number % 100 > 4 and number % 100 < 20) and 2 or ({2, 0, 1, 1, 1, 2})[((number % 10 < 5) and number % 10 or 5) + 1]) + 1 ] end
function secToTime(time)
          local hours = math.floor(time/3600)
          local mins = math.floor(time/60 - (hours*60))
          local secs = math.floor(time - hours*3600 - mins *60)

          return ( hours > 0 and hours .. ' ' .. declOfNum(hours, phrases.declensions.hours) .. ' ' or '' ) .. ( mins > 0 and mins .. ' ' .. declOfNum(mins, phrases.declensions.minutes) .. ' ' or '' ) .. ( secs > 0 and secs .. ' ' .. declOfNum(secs, phrases.declensions.seconds) or '' )
end
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

    vk.call('messages.send', { peer_id = gvObj.peer_id, message = msgTemplate })
end

-- Main function

function obj.func(msg)
  for k, v in pairs(giveaways) do if os.time() > v.end_time then findWinner(v) end end

  if msg.out then
      if msg.body:lower():find('^' .. giveawayStartWord) then
          local time = msg.body:match('^' .. giveawayStartWord .. '%s+(%d+%.*%d*)%s*')
          local str = msg.body:match('^' .. giveawayStartWord .. (time and '%s+%d+%.*%d*' or '') .. '%s+(.+)') or giveawayDefWord
          local timeStr = secToTime(tonumber(time or giveawayDefTime) * 60)

          msg:edit(phrases.giveawayStart:format(str, timeStr))
          giveaways[msg.peer_id] = { trigger = str, time = time, timeStr = timeStr, end_time = os.time() + (time * 60), peer_id = msg.peer_id, msg_id = msg.id, users = { } }
      elseif msg.body:lower():find('^' .. giveawayStop .. '$') then
          findWinner(giveaways[msg.peer_id])
      end
  elseif giveaways[msg.peer_id] and msg.body:lower() == giveaways[msg.peer_id].trigger:lower() and not giveaways[msg.peer_id].users[msg.user_id] then
      local res = vk.call('users.get', { user_ids = msg.user_id })
      giveaways[msg.peer_id].users[msg.user_id] = res[1].first_name

      local gvObj, usersTemplate = giveaways[msg.peer_id], {}
      for k, v in pairs(gvObj.users) do table.insert(usersTemplate, '@id' .. k .. ' (' .. v .. ')') end

      local msgTemplate = phrases.giveawayStart:format(gvObj.trigger, gvObj.timeStr) .. phrases.giveawayUsers:format(#usersTemplate, declOfNum(#usersTemplate, phrases.declensions.users), table.concat(usersTemplate, ', '))

      vk.call('messages.edit', { peer_id = msg.peer_id, message_id = gvObj.msg_id, message = msgTemplate })
  end
end

return obj
