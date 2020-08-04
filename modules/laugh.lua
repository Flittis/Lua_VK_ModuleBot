local config = ...

if not config.laugh then addToConfig('laugh', nil, {}) end

local laughTrigger = config.laugh.trigger or addToConfig('laugh', 'trigger', '!смех')
local laughLength = config.laugh.length or addToConfig('laugh', 'length', {4, 12})
local laughLetters = config.laugh.letters or addToConfig('laugh', 'letters', {'А', 'Х', 'Ф', 'Ы', 'П', 'В', 'С'})

local obj = {}
math.randomseed(os.time())

function obj.func(msg)
  if msg.out and msg.body:lower() == laughTrigger then
    msg:delete(true)

    local laughLength, laughStr = math.random(laughLength[1], laughLength[2]), ''

    for i = 1, laughLength do
      laughStr = laughStr .. laughLetters[math.random(1, #laughLetters)]
    end

    msg:send(laughStr)
  end
end

return obj
