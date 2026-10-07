



local L={installed=false,suppressed=0}

local function belongsToLockedBattle(ctx)
if type(ctx)~="table" then return false end
local battle=ctx.battle
if type(battle)=="table" and battle.cbeMtBattleLevelLock==true then return true end
local mon=ctx.mon or ctx.pokemon
return type(mon)=="table" and mon.__cbeMtBattleLevelLock==true
end

function L.install(mod)
if L.installed then return true end
local hooks=mod and mod.hooks
if not (hooks and type(hooks.wrap)=="function") then return false end
hooks:wrap("battle.exp_award",function(next,ctx,...)
if belongsToLockedBattle(ctx) then
L.suppressed=L.suppressed+1
return nil
end
return next(ctx,...)
end,5000,"mtbattle-level-lock")
L.installed=true
return true
end

L._test={belongsToLockedBattle=belongsToLockedBattle}
return L
