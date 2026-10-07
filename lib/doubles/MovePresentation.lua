


local V=...
local M={version=2,starts=0,sourceStarts=0,nativeAudioFallbacks=0,joinedImpacts=0,lastError=nil}
local function copy(t)local out={};for k,v in pairs(t or {})do out[k]=v end;return out end
local function record(s,id,token)


if token then return s.actors[token] end
local slot=s.core.slots[id];return slot and s.actors[slot.battlerId]
end
local function scope(s,m,fn)
local ctx=m.context
if not ctx then ctx=copy(s.context);ctx.arena=copy(s.context.arena);m.context=ctx end
ctx.services=s.context.services;ctx.groundY=s.context.groundY
ctx.cbeWazaTargets=nil
if m.role=="attack" and #(m.event.targets or {})>1 then
ctx.cbeWazaTargets={}
for _,id in ipairs(m.event.targets) do
local x,z=V.DoublesPresenter.actorAnchor(s.context,id)
if x and z then ctx.cbeWazaTargets[#ctx.cbeWazaTargets+1]={x,z} end
end
end
local records={player=record(s,m.source,m.sourceBattlerId),enemy=record(s,m.target,m.targetBattlerId)}
for side,id in pairs({player=m.source,enemy=m.target})do


local x,z,dx,dz=V.DoublesPresenter.actorAnchor(s.context,id)
ctx.arena[side]={x,z}
local a=records[side] and records[side].actor
if a and a.matrix then a:matrix(x,ctx.groundY or 0,z,dx,dz) end
end
local C,W,H=V.CurrentSpriteModels,V.WazaSequenceRuntime,V.WazaHandlers



ctx.cbeRetailScaleSelectors={};ctx.cbeRetailScaleSelectorsComplete=true
if C and type(C.retailScaleSelector)=="function" then
for _,id in ipairs({'player-left','player-right','enemy-left','enemy-right'})do
local slot=s.core.slots and s.core.slots[id]
if slot and slot.mon then
local rec=s.actors and s.actors[slot.battlerId]
local selector=rec and rec.actor and C:retailScaleSelector(rec.actor) or nil
if selector==nil then ctx.cbeRetailScaleSelectorsComplete=false
else ctx.cbeRetailScaleSelectors[#ctx.cbeRetailScaleSelectors+1]=selector end
end
end
else ctx.cbeRetailScaleSelectorsComplete=false end
local world=m.world
if not world then
world={active={},particles={},models={},effects={},controllers={player={},enemy={}}};m.world=world
end


local active,last,particles=W and W.active,W and W.last,C.moveFxActive
local models,effects,controllers,lastModel
if H then models,effects,controllers,lastModel=H.models,H.effects,H.controllers,H.lastModel
H.models,H.effects,H.controllers,H.lastModel=world.models,world.effects,world.controllers,world.lastModel end
if W then W.active,W.last=world.active,world.last end
C.moveFxActive=world.particles
local ok,a,b=pcall(C.withDoublesPair,C,ctx,records,fn)
world.particles=C.moveFxActive;C.moveFxActive=particles
if W then world.active,world.last=W.active,W.last;W.active,W.last=active,last end
if H then
world.models,world.effects,world.controllers,world.lastModel=H.models,H.effects,H.controllers,H.lastModel
H.models,H.effects,H.controllers,H.lastModel=models,effects,controllers,lastModel
end
if not ok then error(a) end
return a,b
end
local function nativeAudio(s,m)
if s.generation==3 then return end
local req=V.engineRequire or require
local ok,Sound=pcall(req,'src.core.Sound');if not ok then M.lastError=tostring(Sound);return end
local data=s.screen.game.data;local def=m.event.moveDef or {}
if s.generation==2 then
local anims=data.gen2BattleAnims;local key=anims and anims.moves and anims.moves[m.event.move]
local loaded,Runner=pcall(req,'src.battle.gen2.AnimRunner')
local result=(m.event.targetResults or {})[m.target] or {}
if loaded and key then
m.audioRunner=Runner.new{data=anims,constants=s.screen.animConstants,battleTurn=0,animId=m.event.move,param=tonumber(result.animParam) or 0,
sfxOrder=(data.audio or {}).sfxOrder,hooks={sound=function(name)if name then Sound.playStereo(data,name)end end,
cry=function(side)local rec=record(s,side=='enemy' and m.target or m.source,side=='enemy' and m.targetBattlerId or m.sourceBattlerId);if rec and rec.mon then Sound.playCry(data,rec.mon.species) end end}}
m.audioRunner:start(key);m.audioClock=0
elseif def.anim and Sound.playMove then Sound.playMove(data,def.anim) end
elseif def.anim and Sound.playMove then Sound.playMove(data,def.anim) end
M.nativeAudioFallbacks=M.nativeAudioFallbacks+1
end
local function channel(e)
local source=e.kind=='move' and e.slot or e.sourceSlot
local target=e.kind=='move' and ((e.targets or {})[1] or e.slot) or e.slot
source=source or target
return {event=e,source=source,target=target,
sourceBattlerId=e.kind=='move' and e.battlerId or e.sourceBattlerId or e.battlerId,
targetBattlerId=e.kind=='move' and (e.targetBattlers or {})[target] or e.battlerId,
age=0,role=(e.kind=='damage' or e.kind=='reaction') and 'damage' or 'attack'}
end
local function hasSourceTransit(spec,moveId)
local C=V.CurrentSpriteModels
if not (type(spec)=='table' and C and C.particleTransitSpan) then return false end
for _,phase in ipairs(spec.wazaPhases or {})do
local name=tostring(phase.name or ''):lower()
if not name:match('^damage') and name~='status' then
for _,entry in ipairs(phase.entries or {})do
if entry.kind=='particle' and C:particleTransitSpan(moveId,'attack',entry)~=100 then return true end
end
end
end
return false
end
function M.begin(s,e)


if e.presentationConsumed then e.presentationPending=nil;e.duration=0;e.automatic=true;return end
M.finish(s)
if e.kind=='move' then
local r=record(s,e.slot,e.battlerId)
if r and e.structuralHiddenBefore~=nil then
r.structuralHidden=(not e.release) and e.structuralHiddenBefore==true
if e.structuralHiddenAfter==false then r.structuralHidden=false end
end
end
local m=channel(e);m.channels={m};s.movePresentation=m
e.presentationPending=true;M.starts=M.starts+1
end
local function start(s,m,a)
if m.started then return end
m.started=true;m.chapterAge=0
local e=m.event;local spec=m.spec
local rootEvent=m.parent and m.parent.event or e
local sourceOwned=s.generation==3 and rootEvent.sourceOwned==true
local duration=a and a.stateDuration and a:stateDuration(m.role=='damage' and 'hit' or 'attack') or .95
m.bodyDuration=math.max(.4,tonumber(duration) or .95)
local sourcePoints





if spec then
local points=a and a.wazaTimingPoints and a:wazaTimingPoints()
m.timingPoints=points
sourcePoints=points
if m.role=='damage' and type(points)=='table' and tonumber(points[1]) and points[1]>0 then




sourcePoints={};for i,v in ipairs(points)do sourcePoints[i]=v-points[1]end
m.receivingOrigin=points[1]
end
scope(s,m,function(ctx)
m.instance,m.error=V.CurrentSpriteModels:startDoublesWaza(ctx,spec,{role=m.role,target='enemy',moveId=e.move,move=e.moveDef,
allowPartial=not sourceOwned,globalTimingPoints=sourcePoints,presentationFrames=math.floor(m.bodyDuration*60+.5)})
end)
if m.instance then M.sourceStarts=M.sourceStarts+1 elseif m.role=='attack' then M.lastError=tostring(m.error) end


local H=V.WazaHandlers
if m.instance and m.world and H and H.sideWorlds then H.sideWorlds[m.world]=true end
elseif e.move then M.lastError='Source move not cached: '..tostring(e.move) end
if not m.instance and sourceOwned and V.Gen3Presentation and V.Gen3Presentation.failSourceMove then
local fellBack=V.Gen3Presentation.failSourceMove(rootEvent,m.error or M.lastError or 'source Waza chapter could not start')




if fellBack and spec and V.WazaSequenceRuntime and V.WazaSequenceRuntime.hasVisibleRole
and V.WazaSequenceRuntime:hasVisibleRole(spec,m.role) then
scope(s,m,function(ctx)
m.instance,m.partialError=V.CurrentSpriteModels:startDoublesWaza(ctx,spec,{role=m.role,target='enemy',
moveId=e.move,move=e.moveDef,allowPartial=true,globalTimingPoints=sourcePoints,
presentationFrames=math.floor(m.bodyDuration*60+.5)})
end)
if m.instance then m.partialRecovery=true;M.sourceStarts=M.sourceStarts+1
local H=V.WazaHandlers
if m.world and H and H.sideWorlds then H.sideWorlds[m.world]=true end
end
end
end
if V.FxDiagnostics then pcall(V.FxDiagnostics.note,'move.start',{move=e.move,role=m.role,stem=spec and spec.stem,
instance=m.instance~=nil,error=m.error,body=m.bodyDuration,actor=a~=nil}) end
if m.role=='attack' then
local ready=m.instance and spec and V.WazaAudioRuntime and V.WazaAudioRuntime.readyForSpec(spec)
if not ready then nativeAudio(s,m) end
end
if m.parent and not e.statusVisual then


if s.core.presentImpact and s.core:presentImpact(e,m.bodyDuration) then
M.joinedImpacts=M.joinedImpacts+1
m.parent.impactStarted=true;m.parent.impactAge=0
end
else e.duration=m.bodyDuration end
if m.role=='attack' then
local points=m.timingPoints or {}
local timing=tonumber(points[2])
if not timing or timing<=0 then timing=tonumber(points[1]) end
if not timing or timing<=0 or timing/60>m.bodyDuration then timing=m.bodyDuration*60*.58;m.impactTimingFallback=true end
m.impactTime=math.max(.08,timing/60)
local id=tonumber(m.spec and m.spec.moveId)



m.awaitTransit=hasSourceTransit(m.spec,id)
end
end
local function updateChannel(s,m,dt)
if m.done then return end
m.age=m.age+dt
if not m.requested then
local rec=record(s,m.role=='damage' and m.target or m.source,m.role=='damage' and m.targetBattlerId or m.sourceBattlerId);local a=rec and rec.actor
if a or m.age>.75 then
m.requested=true
local source=record(s,m.source,m.sourceBattlerId)
local sourceActor=source and source.actor
local spec=m.event.move and V.MoveFXExtractor and V.MoveFXExtractor.peek(m.event.move,m.event.moveDef)
if not spec and m.event.move and V.MoveFXExtractor and V.MoveFXExtractor.queuePrefetch then

pcall(V.MoveFXExtractor.queuePrefetch,m.event.move,m.event.moveDef,s.context.battle)
end
if spec then
local dex=sourceActor and sourceActor.dex
if not dex and source and source.mon then
local data=s.screen and s.screen.game and s.screen.game.data
local def=data and data.pokemon and data.pokemon[source.mon.species];dex=def and (def.dex or def.index or def.number)
end
local selectionMoveId=tonumber(m.event.move)
or (type(m.event.moveDef)=='table' and (tonumber(m.event.moveDef.index) or tonumber(m.event.moveDef.colosseumMoveId)))
or tonumber(spec.moveId)
local sourceModelId=sourceActor and sourceActor.sourceModelId
if dex==351 and s.generation==3 and not sourceModelId then
local g3=V.Gen3Presentation;local r=g3 and g3.records and g3.records[m.sourceBattlerId]
sourceModelId=r and r.sourceModelId
if not sourceModelId then
local okUi,ui=pcall(V.engineRequire or require,'src.core.game3.battle.ui')
local native=source and source.battler and (source.battler.native or source.battler)
if okUi and ui and type(ui.castformForm)=='function' and native and V.ColosseumSpeciesIndex then
local ok,form=pcall(ui.castformForm,m.sourceBattlerId,native)
if ok then sourceModelId=V.ColosseumSpeciesIndex.castformModelForForm(form) end
end
end
end
spec=V.WazaPhasePolicy.select(spec,{moveId=selectionMoveId,dex=dex,sourceModelId=sourceModelId,
stage=m.event.stage or 'attack',statusMove=m.event.statusMove==true or (m.parent and m.parent.event.statusMove==true)})
m.spec=spec
end
local nativeSlot,sequenceKind
if spec and V.CurrentSpriteModels.sourceNativeSlot then
nativeSlot,sequenceKind=V.CurrentSpriteModels:sourceNativeSlot(spec,m.role)
end
local opts={nativeSlot=nativeSlot,sourceSequenceKind=sequenceKind,deferFaint=s.generation==3,
onStarted=function(actor)m.startActor=actor;m.startReady=true end}
if a then
if m.event.statusVisual then start(s,m,a)
elseif m.role=='damage' then a:hit({damage=m.event.amount,target={hp=m.event.hp}},opts)
else a:attack(m.event.move,m.event.moveDef,opts) end
end

if not a then start(s,m,nil) end
end
end



if m.startReady and not m.started then start(s,m,m.startActor);m.startReady=nil end
if m.requested and not m.started and m.age>2 then start(s,m,nil) end
if not m.started then return end
m.chapterAge=m.chapterAge+dt
scope(s,m,function(ctx)
V.WazaSequenceRuntime:update(ctx,dt)
V.CurrentSpriteModels:updateReleaseFx(ctx,dt)
end)
M.applyOwnerModulation(s,m)
if V.FxDiagnostics then pcall(V.FxDiagnostics.sample,m,'move.tick',{move=m.event.move,role=m.role,age=m.chapterAge},.25) end
if m.audioRunner then
m.audioClock=m.audioClock+dt
while m.audioClock>=1/60 do m.audioClock=m.audioClock-1/60;if not m.audioRunner:step() then m.audioRunner=nil;break end end
end
local sourceDone=not m.instance or m.instance.done
local particlePending=scope(s,m,function()
return V.CurrentSpriteModels.hasDoublesWazaParticles and V.CurrentSpriteModels:hasDoublesWazaParticles(m.instance)
end)


local hold=m.role=='damage' and math.min(m.bodyDuration,M.DAMAGE_HOLD) or m.bodyDuration
if (sourceDone and not particlePending and not m.audioRunner and m.chapterAge>=hold) or m.chapterAge>32 then
if m.chapterAge>32 then M.timeouts=(M.timeouts or 0)+1;M.lastError='Doubles source chapter timeout: '..tostring(m.event.move);s.presentationError=M.lastError end
m.done=true;M.releaseTrack(s,m)
end
end
local function readyForImpact(m)
local timingReady=(m.chapterAge or 0)>=(m.impactTime or .5)
if not m.awaitTransit then return timingReady end



if not timingReady then return false end



local C=V.CurrentSpriteModels
if C and C.particleTransitSpan then
for _,fx in ipairs(m.world and m.world.particles or {})do
local span=C:particleTransitSpan(m.spec and m.spec.moveId,'attack',fx.wazaEntry)
if span~=100 and not fx.modelLinked then
for _,p in ipairs(fx.vm and fx.vm.particles or {})do
local progress=C.particleTransitProgress and C:particleTransitProgress(fx,p)
local arrived=(progress~=nil and progress>=.90) or (progress==nil and p.position and (tonumber(p.position[3]) or 0)>=span*.90)
if p.alive~=false and arrived then
m.impactTimingSource='source-waza+particle-arrival';return true
end
end
end
end
end


if m.done or (not m.instance and (m.chapterAge or 0)>=(m.impactTime or .5)) then
m.impactTimingSource='source-unavailable-or-finished';return true
end
return false
end



M.DAMAGE_HOLD=.50
function M.presentationDt(s,dt)
local TP=V.TrainerPerformance
local speed=TP and TP.speed and TP.speed(s and s.context) or 1


local T=V.BattleTempo
local ctx=s and s.context
local rate=T and T.presentationRate and T.presentationRate(ctx and (ctx.game or (ctx.battle and ctx.battle.game))) or 1
local frame=ctx and ctx.services and ctx.services.presentationFrameClock
return math.max(0,math.min(.1*rate,(tonumber(dt) or 0)/(frame and 1 or speed)*rate))
end
function M.update(s,dt)
local m=s.movePresentation;if not m or not s.context then return end
dt=M.presentationDt(s,dt)
updateChannel(s,m,dt)
if m.started and not m.impactsQueued and readyForImpact(m) then
m.impactsQueued=true
for _,e in ipairs(m.event.impacts or {}) do
if e.impactOf==m.event.eventId and not e.presentationConsumed then
local child=channel(e);child.parent=m
m.channels[#m.channels+1]=child
end
end



if #(m.event.impacts or {})==0 and m.event.statusMove and m.spec and m.spec.phaseSelection
and m.spec.phaseSelection.damage then
local e=m.event
local target=e.target or ((e.targets or {})[1])
local targetId=target and (e.targetBattlers or {})[target]
if target and targetId~=nil then
local status={kind='damage',statusVisual=true,sourceSlot=e.slot,
sourceBattlerId=e.battlerId,slot=target,battlerId=targetId,
move=e.move,moveDef=e.moveDef,eventId=tostring(e.eventId)..':status'}
local child=channel(status);child.parent=m
m.channels[#m.channels+1]=child
end
end
end
local allDone=m.done==true
for i=2,#m.channels do
local child=m.channels[i];updateChannel(s,child,dt)
if child.event.presentationConsumed then
child.event.impactElapsed=(child.event.impactElapsed or 0)+dt
end
if not child.done then allDone=false end
end
if m.impactStarted then m.impactAge=(m.impactAge or 0)+dt end
if allDone and (m.impactsQueued or #(m.event.impacts or {})==0) then M.finish(s,true) end
end






function M.sourceCameraPose(s)
local m=s and s.movePresentation;local H=V.WazaHandlers
if not (m and s.context and H and type(H.cameraPose)=='function' and V.CurrentSpriteModels) then return nil end
local channels=m.channels or {m}
for i=#channels,1,-1 do
local track=channels[i]
if track and track.started and not track.done and track.world then
local ok,pose=pcall(scope,s,track,function(ctx)return H.cameraPose(ctx)end)
if ok and type(pose)=='table' and pose.eye and pose.focus and pose.fov then
pose.sourceCameraPresentationClock=true
pose.cbeCameraBattlerId=pose.sourceRole=='damage' and track.targetBattlerId or track.sourceBattlerId
if pose.sourceCameraEmbeddedDecoded==true and pose.sourceCameraRetailFrameExact==true
and pose.sourceCameraEmbeddedTransformUnsupported==nil then return pose end
if pose.sourceCameraEmbedded~=true and pose.sourceCameraEmbeddedTransformUnsupported==nil
and pose.sourceCameraMotionScalarExact==true
and pose.sourceCameraTargetResolved==true then return pose end

return nil
end
end
end
return nil
end
function M.draw(s,context)
local m=s.movePresentation;if not m then return end
s.context=context
for _,track in ipairs(m.channels or {m}) do
if track.started and not track.done then
scope(s,track,function(ctx)
local models=V.WazaHandlers and V.WazaHandlers.drawWorld(ctx) or false
local particles=V.CurrentSpriteModels:drawReleaseFx(ctx) or false
track.__fxDiagDrew=(models and 'M' or '-')..(particles and 'P' or '-')
end)
end
end
end


function M.applyOwnerModulation(s,m)
local H=V.WazaHandlers
if not (H and H.ownerModulation and m.world) then return end
local origin=m.role=='damage' and record(s,m.target,m.targetBattlerId) or record(s,m.source,m.sourceBattlerId)
local a=origin and origin.actor;if not a then return end
local mod=H.ownerModulation(m.world.effects)
if mod then a.sourceModulation=mod;m.modulatedActor=a
elseif m.modulatedActor==a and not a.cbeSourceFaintReturn then a.sourceModulation=nil;m.modulatedActor=nil end
end
function M.releaseTrack(s,m)
local H=V.WazaHandlers
if m.world and H and H.sideWorlds then H.sideWorlds[m.world]=nil end
local a=m.modulatedActor
if a and not a.cbeSourceFaintReturn then a.sourceModulation=nil end
m.modulatedActor=nil
end
function M.drawPost(s,ctx,canvas,w,h)
local m=s.movePresentation;local H=V.WazaHandlers
if not m or not H or not H.drawPost then return false end
local previous=H.effects;local combined={}
for _,track in ipairs(m.channels or {m}) do
if track.world and not track.done then
for key,value in pairs(track.world.effects or {}) do combined[key]=value end
end
end
H.effects=combined
local ok,result=pcall(H.drawPost,ctx,canvas,w,h)
H.effects=previous
if not ok then error(result) end
return result
end
function M.finish(s,completed)
local m=s.movePresentation;if not m then return end
if completed and m.event.kind=='move' and m.event.structuralHiddenAfter~=nil then
local r=record(s,m.source,m.sourceBattlerId)
if r then r.structuralHidden=m.event.structuralHiddenAfter==true end
end
for _,track in ipairs(m.channels or {m}) do
M.releaseTrack(s,track)
if track.world and (track.context or s.context) then
scope(s,track,function(ctx)V.CurrentSpriteModels:clearDoublesWaza(ctx)end)
end
track.event.presentationPending=nil
end
m.event.presentationPending=nil;s.movePresentation=nil
end
function M.actorDt(s,r,dt)
local m=s and s.movePresentation
local TP=V.TrainerPerformance
if m then dt=M.presentationDt(s,dt)
elseif TP and TP.pokemonDt then dt=TP.pokemonDt(s and s.context,dt,r.actor) end
if not m or not r.actor or r.actor.state=='faint' or r.actor.pendingFaint then return dt end
for _,track in ipairs(m.channels or {m}) do
local side=r.battlerId==track.sourceBattlerId and 'player' or (r.battlerId==track.targetBattlerId and 'enemy')
local c=track.world and track.world.controllers
if not track.done and side and c and c[side] and c[side].motionFrozen then return 0 end
end
return dt
end
function M.visible(s,r)
if r.structuralHidden then return false end
local m=s.movePresentation;if not m then return true end
for _,track in ipairs(m.channels or {m}) do
local side=(r.battlerId==track.sourceBattlerId) and 'player' or ((r.battlerId==track.targetBattlerId) and 'enemy')
local controls=track.world and track.world.controllers
if side and controls and controls[side] and controls[side].hidden==true then return false end
end
return true
end
function M.status(s)
local m=s and s.movePresentation;local channels={}
for _,track in ipairs(m and m.channels or {}) do
channels[#channels+1]={role=track.role,source=track.source,target=track.target,age=track.chapterAge,
started=track.started,done=track.done,serial=track.instance and track.instance.serial,
particles=track.world and #track.world.particles or 0}
end
return {version=M.version,channels=channels,joinedImpacts=M.joinedImpacts,timeouts=M.timeouts or 0,lastError=M.lastError}
end
M._test={scope=scope,channel=channel,readyForImpact=readyForImpact,hasSourceTransit=hasSourceTransit}
return M
