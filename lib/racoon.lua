-- REV: Название файла откровенно плохое - оно не говорит, за что отвечает этот модуль
-- А поскольку он отвечает за работу с файлами и логами, стоит это как-то подчеркнуть в названии.
-- Но еще лучше - вынести в один файл функции работы с логом, назвать racoonLogger, а в другой - работу с конфигом, назвать racoonConfigManager, например
local io = require("io")
local filesystem = require("filesystem")
local serialization = require("serialization")
local color = require("rainbow")
local component = require("component")
local buf = color.buffer()

local racoon = {}
racoon.starttime = os.date("%x_%X"):gsub("[/:]", ".")
racoon.logmode = "both"

-- REV: "Магические числа" - один из самых распространенных антипаттернов
-- В данном случае его можно избежать тремя способами:
-- 1) Создать где-то константы:
--     critical = 4
--     error    = 3
--     ...
--    И использовать их вместо чисел - так код станет гораздо понятнее
-- 2) Передавать аргумент значимости ошибки не числом, а строкой, как это сделано в переменной logMode
-- 3) Разбить функцию log на несколько - logCritical, logError и так далее - этот вариант мне нравится больше
function racoon.log(text, mtype, progname)
  if mtype == 4 then
    racoon.lograw("["..os.date("%x %X").."] [CRITACAL]: "..text, progname) -- REV: Очепятка
  elseif mtype == 3 then
    racoon.lograw("["..os.date("%x %X").."] [ERROR]: "..text, progname)
    -- REV: os.date() обычно возвращает бредовые и непредсказуемые значения типа 1970 года
    -- Лучше в качестве временной метки использовать количество секунд, прошедшее с запуска программы
  elseif mtype == 2 then
    racoon.lograw("["..os.date("%x %X").."] [WARNING]: "..text, progname)
  elseif mtype == 0 then
    racoon.lograw("["..os.date("%x %X").."] [INIT]: "..text, progname)
  else
    racoon.lograw("["..os.date("%x %X").."] [INFO]: "..text, progname)
  end
end

-- REV: Лучше предусмотреть обработку случая progname == nil
function racoon.logtofile(text, progname)
  if not filesystem.exists("/etc/log/") then filesystem.makeDirectory("/etc/log/") end
  logfile = io.open("/etc/log/"..progname.."_"..racoon.starttime..".log","a")
  logfile:write(text.."\n")
  logfile:close()
end

function racoon.logtoscreen(text)
if text:find("CRITACAL") then -- REV: Очепятка
  print(buf(buf.bg_red(buf.fg_black(text)), buf.bg_black(buf.fg_white(""))))
elseif text:find("ERROR") then
  print(buf(buf.fg_red(text), buf.bg_black(buf.fg_white(""))))
elseif text:find("WARNING") then
  print(buf(buf.fg_yellow(text), buf.bg_black(buf.fg_white(""))))
elseif text:find("INIT") then
  print(buf(buf.fg_green(text), buf.bg_black(buf.fg_white(""))))
else
  print(buf(buf.fg_white(text), buf.bg_black(buf.fg_white(""))))
end
end

function racoon.lograw(text, progname)
  if racoon.logmode == "both" then
    racoon.logtoscreen(text)
    racoon.logtofile(text, progname)
  elseif racoon.logmode == "print" then
    racoon.logtoscreen(text)
  else
    racoon.logtofile(text, progname)
  end
end

function racoon.writeconfig(progname, config)
  if not filesystem.exists("/etc/config/") then filesystem.makeDirectory("/etc/config/") end
  local configfile = io.open("/etc/config/"..progname..".cfg","w")
  configfile:write(serialization.serialize(config))
  configfile:close()
end

function racoon.readconfig(progname)
  local configfile = io.open("/etc/config/"..progname..".cfg","r")
  if not configfile then configfile = io.open("/etc/config/"..progname..".cfg","w") end
  local file = configfile:read()
  if not file then file = "{}" end
  local config = serialization.unserialize(file)
  configfile:close()
  return config
end

function racoon.readlang(progname)
  local lang = sysconfig.lang
  if not filesystem.exists("/etc/lang/") then filesystem.makeDirectory("/etc/lang/") end
  local langfile = io.open("/etc/lang/"..lang.."."..progname..".lang","r")
  if not langfile then return nil end
  local lang = serialization.unserialize(langfile:read())
  if not lang then return nil end
  langfile:close()
  return lang
end

function racoon.gettheme()
  local themefile
  if not filesystem.exists("/etc/themes/") then filesystem.makeDirectory("/etc/themes/") end
  if component.gpu.maxDepth() > 1 then
    themefile = io.open("/etc/themes/"..sysconfig.theme..".thm","r")
  else 
    themefile = io.open("/etc/themes/monochrome.thm","r")
  end
  if not themefile then return nil end
  local theme = serialization.unserialize(themefile:read())
  if not theme then return nil end
  themefile:close()
  return theme
end
return racoon