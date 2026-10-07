local V = ...
local Trainer=V.Trainer
local PlayerTrainer=V.PlayerTrainer








local N = {
installed=false, activeBattle=nil, error=nil,
picsWrapper=nil,
installs=0,
}

local function presentation(battle)
local compat=V.GenerationCompat
return compat and compat.prepare(battle) or battle
end

local function sameBattle(a,b)
local compat=V.GenerationCompat
return (compat and compat.matches(a,b)) or a==b
end

local function suppress(battle)
battle=presentation(battle)
if type(battle)~="table" or not sameBattle(battle,N.activeBattle) then return false end
if battle.safari or battle.demo then return false end
return battle.kind=="trainer" or battle.kind=="wild"
end

local function providerVisible(provider,battle,side)
if not (provider and type(provider.shouldRender)=="function") then return false end
local ok,value=pcall(provider.shouldRender,provider,{battle=battle,game=battle and battle.game})
if not (ok and value==true) then return false end





local arena=V and V.Arena
if arena and type(arena.status)=="function" then
local aok,ast=pcall(arena.status,arena)
local errors=aok and type(ast)=="table" and ast.renderErrors or nil
local key=side=="player" and "playerTrainer" or "enemyTrainer"
if type(errors)=="table" and errors[key] then return false end
end
if type(provider.status)=="function" then
local sok,st=pcall(provider.status,provider)
if sok and type(st)=="table" then return st.active==true and st.ready==true end
end
return false
end

local function trainerMask(battle)
battle=presentation(battle)
if not suppress(battle) then return false,false end
local hidePlayer=battle.showPlayerBack and providerVisible(PlayerTrainer,battle,"player") or false
local hideEnemy=battle.showEnemyTrainer and providerVisible(Trainer,battle,"enemy") or false
return hidePlayer,hideEnemy
end

local function wrapMethod(BattleState,name,slot,make)
local current=BattleState[name]
if type(current)~="function" then return true end
if current==N[slot] then return true end
local wrapper=make(current)
N[slot]=wrapper
BattleState[name]=wrapper
return true
end

function N.install(force)
local req=V.engineRequire or require
local ok,BattleState=pcall(req,"src.battle.BattleState")
if not ok or type(BattleState)~="table" then
N.error=tostring(BattleState); return false,N.error
end




wrapMethod(BattleState,"drawPicsLayer","picsWrapper",function(inner)
return function(self,slide,sx,sy,onlySide,skipMenuClip)
local hidePlayer,hideEnemy=trainerMask(self)
if not hidePlayer and not hideEnemy then
return inner(self,slide,sx,sy,onlySide,skipMenuClip)
end


if onlySide=="player" then
if hidePlayer then return end
return inner(self,slide,sx,sy,onlySide,skipMenuClip)
elseif onlySide=="enemy" then
if hideEnemy then return end
return inner(self,slide,sx,sy,onlySide,skipMenuClip)
end

if hidePlayer and hideEnemy then return end

if hidePlayer then
return inner(self,slide,sx,sy,"enemy",skipMenuClip)
end
return inner(self,slide,sx,sy,"player",skipMenuClip)
end
end)







N.installed=true; N.error=nil; N.installs=N.installs+1
return true
end

function N:begin(ctx)
local battle=type(ctx)=="table" and (ctx.battle or (ctx.kind and ctx)) or nil
battle=presentation(battle)
if battle and not battle.safari and not battle.demo then
self.activeBattle=battle



if not self.installed then self.install() end
end
end

function N:finish(ctx)
local battle=type(ctx)=="table" and (ctx.battle or (ctx.kind and ctx)) or nil
battle=presentation(battle)
if not battle or sameBattle(self.activeBattle,battle) then self.activeBattle=nil end
end

function N:hides(battle,side)
local hidePlayer,hideEnemy=trainerMask(presentation(battle))
return side=="player" and hidePlayer or side=="enemy" and hideEnemy or false
end

function N.status()
return {
installed=N.installed,
active=N.activeBattle~=nil,
error=N.error,
installs=N.installs,
scope="ready-and-active-3d-trainer-only; runtime-cache-failure-keeps-native-trainer-art",
}
end
return N
