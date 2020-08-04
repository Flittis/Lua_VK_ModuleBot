local config = ...

if not config.morse then addToConfig('morse', nil, {}) end

local morseTrigger = config.morse.trigger or addToConfig('morse', 'trigger', '!морзянка')

function isInObject(t, v) for k, _ in pairs(t) do if k == v then return true end end return false end

local obj = {}

function obj.func(msg)
  if msg.out and msg.body:lower():find('^' .. morseTrigger) then
    local thisMsg = ''

    if msg.body:lower():match('^' .. morseTrigger .. '%s+(.+)') then
      thisMsg = msg.body:lower():match('^' .. morseTrigger .. '%s+(.+)')
    else
      local res = vk.call('messages.getById', { message_ids = msg.id })
      if res.error then return end

      if res.items and res.items[1] and (res.items[1].reply_message or res.items[1].fwd_messages) then
        local i = res.items[1].reply_message or res.items[1].fwd_messages

        if i.text then thisMsg = i.text else return end
      end
    end

    msg:edit(translate(thisMsg))
  end
end



local dot, dash, betwenLetters, space = '·', '–', 'ᅠ', ' '
local letters = {

  -- Russian Letters

  ['а'] = (dot .. dash), ['б'] = (dash .. dot .. dot .. dot), ['в'] = (dot .. dash .. dash), ['г'] = (dash .. dash .. dot), ['д'] = (dash .. dot .. dot), ['е'] = (dot), ['ж'] = (dot .. dot .. dot .. dash), ['з'] = (dash .. dash .. dot .. dot),
  ['и'] = (dot .. dot), ['й'] = (dot .. dash .. dash .. dash), ['к'] = (dash .. dot .. dash), ['л'] = (dot .. dash .. dot .. dot), ['м'] = (dash .. dash), ['н'] = (dash .. dot), ['о'] = (dash .. dash .. dash), ['п'] = (dot .. dash .. dash .. dot),
  ['р'] = (dot .. dash .. dot), ['с'] = (dot .. dot .. dot), ['т'] = (dash), ['у'] = (dot .. dot .. dash), ['ф'] = (dot .. dot .. dash .. dot), ['х'] = (dot .. dot .. dot .. dot), ['ц'] = (dash .. dot .. dash .. dot), ['ч'] = (dash .. dash .. dash .. dot),
  ['ш'] = (dash .. dash .. dash .. dash), ['щ'] = (dash .. dash .. dot .. dash), ['ъ'] = (dot .. dash .. dash .. dot .. dash .. dot), ['ы'] = (dash .. dot .. dash .. dash), ['ь'] = (dash .. dot .. dot .. dash), ['э'] = (dot .. dot .. dash .. dot .. dot),
  ['ю'] = (dot .. dot .. dash .. dash), ['я'] = (dot .. dash .. dot .. dash),

  -- English Letters

  ['a'] = (dot .. dash), ['b'] = (dash .. dot .. dot .. dot), ['c'] = (dash .. dot .. dash .. dot), ['d'] = (dash .. dot .. dot), ['e'] = (dot), ['f'] = (dot .. dot .. dash .. dot), ['g'] = (dash .. dash .. dot), ['h'] = (dot .. dot .. dot .. dot),
  ['i'] = (dot .. dot), ['j'] = (dot .. dash .. dash .. dash), ['k'] = (dash .. dot .. dash), ['l'] = (dot .. dash .. dot .. dot), ['m'] = (dash .. dash), ['n'] = (dash .. dot), ['o'] = (dash .. dash .. dash), ['p'] = (dot .. dash .. dash .. dot),
  ['q'] = (dash .. dash .. dot .. dash), ['r'] = (dot .. dash .. dot), ['s'] = (dot .. dot .. dot), ['t'] = (dash), ['u'] = (dot .. dot .. dash), ['v'] = (dot .. dot .. dot .. dash), ['w'] = (dot .. dash .. dash), ['x'] = (dash .. dot .. dot .. dash),
  ['y'] = (dash .. dot .. dash .. dash), ['z'] = (dash .. dash .. dot .. dot),

  -- Symbols and Numbers

  ['0'] = (dash .. dash .. dash .. dash .. dash), ['1'] = (dot .. dash .. dash .. dash .. dash), ['2'] = (dot .. dot .. dash .. dash .. dash), ['3'] = (dot .. dot .. dot .. dash .. dash), ['4'] = (dot .. dot .. dot .. dot .. dash), ['5'] = (dot .. dot .. dot .. dot .. dot),
  ['6'] = (dash .. dot .. dot .. dot .. dot), ['7'] = (dash .. dash .. dot .. dot .. dot), ['8'] = (dash .. dash .. dash .. dot .. dot), ['9'] = (dash .. dash .. dash .. dash .. dot), ['.'] = (dot .. dash .. dot .. dash .. dot .. dash), [','] = (dash .. dash .. dot .. dot .. dash .. dash),
  ['?'] = (dot .. dot .. dash .. dash .. dot .. dot), ["'"] = (dot .. dash .. dash .. dash .. dash .. dot), ['!'] = (dash .. dot .. dash .. dot .. dash .. dash), ['/'] = (dash .. dot .. dot .. dash .. dot), ['('] = (dash .. dot .. dash .. dash .. dot), [')'] = (dash .. dot .. dash .. dash .. dot .. dash),
  [':'] = (dash .. dash .. dash .. dot .. dot .. dot), [';'] = (dash .. dot .. dash .. dot .. dash .. dot), ['='] = (dash .. dot .. dot .. dot .. dash), ['+'] = (dot .. dash .. dot .. dash .. dot), ['-'] = (dash .. dot .. dot .. dot .. dot .. dash), ['"'] = (dot .. dash .. dot .. dot .. dash .. dot),
  ['@'] = (dot .. dash .. dash .. dot .. dash .. dot),
}

local rev_letters = {}
for k, v in pairs(letters) do if not k:find('[a-z]') then rev_letters[v] = k end end

function translate(str)
	local result = ''

	for thisWord in str:gmatch('%S+') do
    if thisWord:lower():find('[' .. dot .. ']+') and thisWord:lower():find('[' .. dash .. ']+') then
      for thisLetter in thisWord:gmatch('[^' .. betwenLetters .. ']+') do if rev_letters[thisLetter:lower()] then result = result .. rev_letters[thisLetter:lower()] end end
    else
      for j = 1, #thisWord do
  			local thisLetter = thisWord:sub(j, j)

  			if letters[thisLetter:lower()] then result = result .. letters[thisLetter:lower()] .. betwenLetters end
  		end
    end

    result = result .. space
	end

	return result:sub(1,1):upper() .. result:sub(2)
end

return obj
