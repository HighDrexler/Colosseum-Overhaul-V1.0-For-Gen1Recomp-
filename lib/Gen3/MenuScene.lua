

local V=...
local req=V.engineRequire or require
local S={owners=setmetatable({},{__mode='k'}),wrapped=setmetatable({},{__mode='k'})}
local function snapshot()
local game=V.Gen3Runtime.game or V.mod.game
local session=V.Gen3Runtime.session(game)
return {session=session,map=session and session.map,phase=game and game.phase}
end
local function withContext(ctx,fn,...)
local previous=S.transitionContext;S.transitionContext=ctx
local result={pcall(fn,...)};S.transitionContext=previous
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
function S.register(menu,enabled)
S.owners[menu]=enabled or function() return true end
if S.wrapped[menu] then return end
S.wrapped[menu]=true
for _,key in ipairs({'show','close','handleInput','update'}) do
local original=menu[key]
if type(original)=='function' then menu[key]=function(...)
local eligible=not req('src.core.game3.display').planesBroken
and not req('src.core.game3.battle').isActive() and S.owners[menu](menu)
return withContext(eligible and snapshot() or nil,original,...)
end end
end
end
function S.floating()
if req('src.core.game3.display').planesBroken then return false end
local order=req('src.ui.game3.stack').drawOrder()
if #order==0 then return false end
for _,layer in ipairs(order) do
local enabled=S.owners[layer.mod]
if not enabled or not enabled(layer.mod) then return false end
end
return true
end
function S.install()
if S.installed then return end
local Stack=req('src.ui.game3.stack')
local Display=req('src.core.game3.display')
local Renderer=req('src.render.Renderer')
local Fade=req('src.ui.game3.fade')
local fadeBegin,fadeDraw,fadeClear=Fade.begin,Fade.draw,Fade.clear
Fade.begin=function(mode,speed,done)
local ctx=(mode==Fade.MODE.FROM_BLACK or mode==Fade.MODE.TO_BLACK) and S.transitionContext or nil
S.menuFade=ctx
local callback=done and function(...) return withContext(ctx,done,...) end or nil
return fadeBegin(mode,speed,callback)
end
Fade.clear=function(...) S.menuFade=nil;return fadeClear(...) end
Fade.draw=function(...)
local ctx=S.menuFade;local now=ctx and snapshot()


if ctx and now.session==ctx.session and now.map==ctx.map and now.phase==ctx.phase
and not Display.planesBroken and not req('src.core.game3.battle').isActive() then
Renderer.screenVeil=nil;return
end
return fadeDraw(...)
end
local Shop=req('src.ui.game3.shop_menu');local shopCamera=Shop.isShopCamera
Shop.isShopCamera=function(...)
if S.floating() then return false end
return shopCamera(...)
end
local fullscreen,present,begin=Stack.fullscreen,Display.present,Renderer.beginFrame



Stack.fullscreen=function(...)
if S.selectingWorld then return false end
return fullscreen(...)
end
Renderer.beginFrame=function(self,...)
S.selectingWorld=false
return begin(self,...)
end
Display.present=function(...)
S.selectingWorld=S.floating()
local result={pcall(present,...)}
S.selectingWorld=false
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
S.installed=true
end
return S
