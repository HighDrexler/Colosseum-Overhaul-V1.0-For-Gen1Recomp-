

local V=...
local req=V.engineRequire or require
local C={}
local function context()
local s=V.StandaloneHost.session
return s and s.context
end
function C.reset() C.sequence=nil;C.executingSuccess=false end
function C.cinematic()
local s=C.sequence
return s and s.started and not s.released or false
end
function C.scale(id)
local s=C.sequence
if not (s and s.started and id==s.target) then return 1 end
return V.PlayerTrainer:captureEnemyScale(context())
end
function C.captured(id)
local s=C.sequence
return s and s.started and s.released and s.caught and s.target==id or false
end
local function eligible(st,opts)
local f=V.Gen3Runtime.active;local p=V.Gen3Runtime.prefs()
return f and f._model==st and context() and p.arenasEnabled and not opts.headless
and not req('src.core.game3.battle.anim')._headless
and not (opts.ghostDodge or st.safari or st.pokedude or st.oldManTutorial or st.ghostBattle
or (st.kinds and st.kinds.tutorial))
and V.PlayerTrainer and V.PlayerTrainer.captureStatus
end
function C.install()
if C.installed then return end
local N=req('src.core.game3.battle.catch_seq')
local begin,update,reset=N.begin,N.update,N.reset
N.reset=function(...) C.reset();return reset(...) end
N.begin=function(st,item,caught,shakes,opts)
opts=opts or {}
local result=begin(st,item,caught,shakes,opts)
if eligible(st,opts) then
for i,step in ipairs(N._steps or {}) do if step.kind=='throw' then



step.kind='cbe_capture'
local info=req('src.core.game3.items_data').info(item)
C.sequence={steps=N._steps,index=i,target=N._target or 1,caught=caught,
shakes=shakes,ball=info and info.name or 'POKE_BALL'}
break
end end
end
return result
end
N.update=function(...)
local s=C.sequence
if s and s.steps~=N._steps then s=nil end
if s and s.started and not s.released then
local status=V.PlayerTrainer:captureStatus(context())
if status and status.active then return false end
s.released=true
local stage=V.StandaloneHost.session
if stage then
stage.captureHold=nil
if not s.caught then stage.context.phase='passive';stage.context.progress=0 end
end
end


local A=req('src.core.game3.audio');local wait=A.waitSe
C.executingSuccess=s and s.released and N._steps and N._steps[N._i]
and N._steps[N._i].kind=='capture_success' or false
if C.executingSuccess and V.PlayerTrainer:suppressesNativeCaughtAudio(context()) then
A.waitSe=function() return true end
end
local out={pcall(update,...)}
A.waitSe=wait;C.executingSuccess=false
if not out[1] then error(out[2],0) end
if s and not s.started and N._steps==s.steps and N._i>s.index then
s.started=true
local ctx=context()
local payload={battle=ctx.battle,ball=s.ball,caught=s.caught,shakes=s.shakes,
target=ctx.battle.battlers[s.target]}
V.PlayerTrainer:event(ctx,'battle.ball_thrown',payload)
V.StandaloneHost.event('battle.ball_thrown',payload)
pcall(function() req('src.core.game3.audio').playSe(req('src.core.game3.se_ids').SE_BALL_THROW,{pan=0}) end)
end
return unpack(out,2)
end
C.installed=true
end
return C
