local event = require("event")
local rn ={}

function rn.ver()
  return "RacoonNet v0.2"
  -- REV: Представление версии как строки не очень хорошая идея
  -- Вдруг где-то в коде понадобится, например, убедиться, что какая-то версия больше 0.2?
  -- Или принадлежит промежутку от 0.1 до 0.3? Каждый раз строку парсить?
  -- 
  -- Поэтому предлагаю возвращать версию как два числа - major и minor
  -- Например, в случае v0.2 возвращать major = 0, minor = 2
end

-- REV: Логичнее было бы назвать эту функцию receiveAny
function rn.receiveall(timeout)
  local ev
  ev = {event.pull(timeout,"racoonnet_message")}
  return ev, ev[2], ev[3], table.unpack(ev, 6)
end

function rn.init(data)
  if not data.type then return nil, "Отсутствует конфигурация RacoonNet. Запустите rnconfig."end
  local mod = require("rn_"..data.type)
  return mod:init(data)
end

return rn