local config = ...
local laughTrigger = config.laughTrigger or addToConfig('laughTrigger', '!смех')
local laughLength = config.laughtLength or addToConfig('laughtLength', {4, 12})
local laughLetters = config.laughLetters or addToConfig('laughLetters', {'А', 'Х', 'Ф', 'Ы', 'П', 'В', 'С'})

local obj = {}
math.randomseed(os.time())


function obj.func(msg)
  if msg.body:lower() == laughTrigger then
    msg:delete()

    local laughLength, laughStr = math.random(laughLength[1], laughLength[2]), ''

    for i = 1, laughLength do
      laughStr = laughStr .. laughLetters[math.random(1, #laughLetters)]
    end

    msg:send(laughStr)
  end
end

return obj
