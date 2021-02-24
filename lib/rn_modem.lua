local event = require("event")
local component = require("component")
local card ={}

card.__index=card

function card:directsend(recAddr, recIP, ... )
  return self.proxy.send(recAddr, self.port, recIP, ...)
end

function card:send(recIP, ... )
  if not self.proxy or not self.router then
    return nil, "Сетевая карта не инициализирована"
  end
  return self.proxy.send(self.router, self.port, recIP, self.ip, ...)
end

function card:receive(timeout)
  local ev
  repeat
    ev = {event.pull(timeout,"modem_message")}
    if not ev[1] then return nil end
	  if ev[2] == self.proxy.address and ev[8]=="ping" then
	    self:send(ev[7], "pong" )
	    ev[2]=nil
	  end
  until ev[2] == self.proxy.address and ev[6] == self.ip
  return table.unpack(ev,7)
end

-- REV: Плохое название для функции.
function card:sendrec(recIP, ... )
  local ok,err=self:send(recIP, ... )
  if ok then
    return self:receive(10)
  else
    return ok,err
  end
end

-- REV: Функция необычно длинна - не критично, но лучше бы разбить ее на несколько.
-- Например, отделить простую инициализацю полей (первые ~ 10 строк) от логики, например, получения IP
--
-- Также эта функция, как и многие другие у этих файлов, частично дублируется с другими rn_<> файлами, чего можно избежать, выделив
-- общие части в отдельный метод(ы)
function card:init(data)
  local obj={}
  setmetatable(obj,self)
  obj.address = data.address
  obj.port = data.port
  obj.master = data.master
  if component.type(obj.address) ~= "modem" then return nil, "Сетевая карта не обнаружена!" end
  obj.proxy = component.proxy(obj.address)
  obj.shortaddr=obj.address:sub(1,3)
  obj.proxy.open(obj.port)
  -- REV: Зачем представлять такие сложные конструкции одной строкой?
  event.listen("modem_message", function (...) local ev = {...} if ev[1] == "modem_message" and ev[2] == obj.address then event.push("racoonnet_message", table.unpack(ev,2))end end)
  if obj.master then
    obj.ip = obj.master
	obj.routerip = obj.master
	obj.router = obj.address
	return obj 
  end
  local ok,err=obj.proxy.broadcast(obj.port,"", "", "getip")
  if not ok then  return ok, err  end
  while true do
    local ev, addr, rout, locip, routip, mess
    ev, addr, rout, _, _, locip, routip, mess = event.pull(1,"modem_message") 
    if ev then
      if addr == obj.proxy.address and mess == "setip" then
        -- REV: Зачем представлять такие сложные конструкции одной строкой?
  	    obj.ip=locip obj.router=rout obj.routerip = routip
        return obj
	  end
    else
      return nil, "Нет ответа от роутера" 
    end
  end
end

return card