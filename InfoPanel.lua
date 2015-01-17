-- ********************************************************************************** --
-- **                                                                              ** --
-- **   Инфо панель для спавна                                                     ** --
-- **                                                                              ** --
-- **   Разработчик: Krutoy                                                        ** --
-- **   Специально для http://computercraft.ru/                                    ** --
-- **                                                                              ** --
-- **   https://github.com/Krutoy242                                               ** --
-- **                                                                              ** --
-- ********************************************************************************** --


--===========================================================
-- Globals
--===========================================================
local component= require "component"
local unicode  = require "unicode"
local gml      = require "gml.gml" 
local canvas   = require "gml.canvas" 
local gfxbuffer= require "gml.gfxbuffer" 
require "xml.XmlParser"

--===========================================================
-- Locals
--===========================================================
local gpu   = component.gpu
local len   = unicode.len
local max   = math.max
local floor = math.floor
local ceil  = math.ceil
local random= math.random

--for k,v in pairs(string) do print(k,v) end

-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                Utilities                                     ** --
-- **                                                                              ** --
-- ********************************************************************************** --
local function wrapString(str, limit, indent, indent1)
  indent = indent or ""
  indent1 = indent1 or indent
  limit = limit or 72
  local here = 1-len(indent1)
  local fo=len(str:match('%S+'))+1
  return indent1..str:gsub("(%s+)()(%S+)()",
                          function(sp, st, word,li)
                            local ol = fo+1
                            fo = fo+len(word)+1
                            if fo-here > limit then
                              here = ol - len(indent)
                              return "\n"..indent..word
                            end
                          end)
end


function reflow(str, limit, indent, indent1)
  return (str:gsub("%s*\n%s+", "\n")
             :gsub("%s%s+", " ")
             :gsub("[^\n]+",
                   function(line)
                     return wrapString(line, limit, indent, indent1)
                   end))
end

function splitLines(str)
  local t = {}
  local function helper(line) table.insert(t, line) return "" end
  helper((str:gsub("(.-)\r?\n", helper)))
  return t
end

-- ********************************************************************************** --
-- **                                                                              ** --
-- **                                UI                                            ** --
-- **                                                                              ** --
-- ********************************************************************************** --

-- Загрузить xml с наполнением
local xml=XmlParser:ParseXmlFile('content.xml')


local wnd_main
local uiW, uiH = tonumber(xml.Attributes.width), tonumber(xml.Attributes.height)   -- Ширина всего интерфейса
local btnW = tonumber(xml.Attributes.btnWidth)
local space = 3
gpu.setResolution(uiW, uiH)
wnd_main = gml.create(1,1,uiW,uiH)
wnd_main.style = gml.loadStyle("gml/style")


-- Заголовок
local lblHeader = wnd_main:addLabel(btnW+space+2,1, uiW-btnW-space-2, "***")
lblHeader.class = "lblHeader"

-- Основной текст
local lblContent = wnd_main:addListBox(btnW+space+2, 3, uiW-btnW-space-4, uiH-4, {"---"})


-- Функции при выборе контента
local function btnPressed(btn)
  local id = btn.id
  
  -- Обновить текст заголовка
  lblHeader.text = xml.ChildNodes[id].ChildNodes[1].Value ..""
  lblHeader:draw()
  
  -- Обновить контент
  local wrappedText = reflow(xml.ChildNodes[id].ChildNodes[2].Value .."", uiW-btnW-space-5,"","  ")
  lblContent:updateList(splitLines(wrappedText, "\n"))
end
btnPressed({id=1})

-- Создать кнопки меню соответственно таблице
local k = 1
for i,xmlNode in pairs(xml.ChildNodes) do
  if(xmlNode.Name=="menu") then
    local level = xmlNode.Attributes.level or 1
    local left   = (level-1)*2
    local menuBtn = wnd_main:addButton(left+1,k,btnW-left,1, xmlNode.Attributes.title, btnPressed)
    menuBtn.id = k
    k = k+1
  elseif(xmlNode.Name=="separator") then
    k = k+1
  end
end

-- Подрисовать разделитель
local function buy_drawBackground()
  gpu.fill(btnW+3, 2, 1, uiH-2, "|")
end
wnd_main.onRun = function() buy_drawBackground() end

-- Какой то обработчик, без которого не воркает
wnd_main:addHandler("key_down",function(event,addy,char,key) end)

wnd_main:run()
