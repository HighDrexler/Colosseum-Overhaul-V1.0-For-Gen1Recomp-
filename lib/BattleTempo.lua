











local V=...
local T={version=1}
T.CHOICES={"game",1,2,4,10}
local hostSpeed=setmetatable({},{__mode="k"})

local function finite(v) return type(v)=="number" and v==v and v>-math.huge and v<math.huge end

local function prefs(game)
local S=V and V.BattleSettings
if S and type(S.prefs)=="function" then
local ok,p=pcall(S.prefs,game or (V.mod and V.mod.game))
if ok and type(p)=="table" then return p end
end
return nil
end

function T.normalize(value)
local n=tonumber(value)
if n then for _,c in ipairs(T.CHOICES) do if c==n then return n end end end
return "game"
end
function T.setting(game)
local p=prefs(game)
return T.normalize(p and p.battleSpeed)
end
function T.label(value)
value=T.normalize(value)
return value=="game" and "MATCH GAME SPEED" or (tostring(value).."X")
end
function T.cycle(game)
local p=prefs(game);if not p then return "game" end
local cur=T.normalize(p.battleSpeed);local idx=1
for i,c in ipairs(T.CHOICES) do if c==cur then idx=i end end
p.battleSpeed=T.CHOICES[idx%#T.CHOICES+1]
return p.battleSpeed
end


function T.inBattle(game)
local G3=V and V.Gen3Runtime
if G3 and G3.active then return true end
local R=V and V.BattleRuntime
if R and R.activeBattle then return true end
return false
end


function T.active(game)
if not T.inBattle(game) then return nil end
local s=T.setting(game)
return s~="game" and s or nil
end


function T.rushEnabled(game) return false end
function T.rush(game)



return 1
end


function T.hostSpeed(game)
local fn=game and hostSpeed[game]
if fn then
local ok,v=pcall(fn,game);v=ok and tonumber(v) or nil
if finite(v) and v>0 then return v end
end
if game and type(game.logicSpeed)=="function" then
local ok,v=pcall(game.logicSpeed,game);v=ok and tonumber(v) or nil
if finite(v) and v>0 then return v end
end
return 1
end




function T.presentationRate(game)
return T.active(game) or 1
end

function T.attach(game)
if type(game)~="table" or type(game.logicSpeed)~="function" then return false end
if game.__cbeBattleTempo==game.logicSpeed then return true end
local inner=game.logicSpeed
hostSpeed[game]=inner
local wrapper=function(self,...)
local tempo=T.active(self)
return tempo or inner(self,...)
end
game.logicSpeed=wrapper;game.__cbeBattleTempo=wrapper
return true
end

function T.status(game)
game=game or (V and V.mod and V.mod.game)
return {setting=T.setting(game),active=T.active(game),host=T.hostSpeed(game),rush=T.rush(game),
attached=game~=nil and game.__cbeBattleTempo~=nil and game.logicSpeed==game.__cbeBattleTempo}
end
return T
