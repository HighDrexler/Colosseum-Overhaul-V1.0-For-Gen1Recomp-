local V=...
local req=V.engineRequire or require
local P={records={},installed=false,clock=0}
local function sourceOwnership(spec,event,id)
local W=V.WazaSequenceRuntime
local audio=V.WazaAudioRuntime



local canOwn=spec and W and W.canOwn and W:canOwn(spec) or false
local audioReady=spec and audio and audio.readyForSpec(spec) or false
local receiving=spec and W and W.hasVisibleRole and W:hasVisibleRole(spec,'damage')
and (event.statusMove or #(event.impacts or {})>0)
local attackVisual=spec and W and W.hasVisibleRole and W:hasVisibleRole(spec,'attack')
local owns=canOwn and audioReady and (attackVisual or receiving) and id~=144 and id~=164
return owns==true,{canOwn=canOwn==true,audioReady=audioReady==true,
attackVisual=attackVisual==true,receivingVisual=receiving==true}
end
P._test={sourceOwnership=sourceOwnership}
local SLOT={[0]='player-left',[1]='enemy-left',[2]='player-right',[3]='enemy-right'}
local function call(actor,name,...)
if actor and actor[name] then return actor[name](actor,...) end
end
local function clearFaint(r,reason)
if r.faintReturn and V.ReleasePresentation then
V.ReleasePresentation.finishFaint(r.faintReturn,r.faintReturn.context,{player=r},reason)
end
r.faintReturn=nil;r.pendingFaint=nil
if r.actor then r.actor.cbeSourceFaintReturn=nil end
end
function P.faintActive()
for _,r in pairs(P.records) do if r.pendingFaint then return r end end
end
function P.faint(id,opts)
local r=P.records[id]
if not (P.session and r and r.actor and r.modelsRequired) then return false end
if r.pendingFaint then return true end
local seq=req('src.core.game3.battle.anim_seq')
r.pendingFaint={steps=seq._steps,onComplete=opts and opts.onComplete}
r.visible=true;r.structuralHidden=nil


r.actor.cbeSourceFaintReturn=true
call(r.actor,'faint','collapse')
P.notify('battle.presentation_faint','faint',id,id)
return true
end
local function updateFaint(r,dt)
local pending=r.pendingFaint;if not pending then return end
if req('src.core.game3.battle.anim_seq')._steps~=pending.steps then
clearFaint(r,'native-queue-replaced');return
end
local a,R=r.actor,V.ReleasePresentation
if not a then clearFaint(r,'actor-replaced');return end
if not r.faintReturn and not pending.sourceFailed and a.state=='faint' then
local delay=R and R.faintStartDelayFor(r.mon,a) or 0
if (a.faintAge or 0)+1e-6>=delay then
local f,why;if R then f,why=R.beginFaint(P.session,r) end
if not f then pending.sourceFailed=true;P.faintError=why or 'Source faint-return unavailable';a.cbeSourceFaintReturn=nil end
if V.FxDiagnostics then pcall(V.FxDiagnostics.note,'faint.begin',{battler=r.battlerId,dex=r.dex,ok=f~=nil,why=why,delay=delay,
faintAge=a.faintAge,stem=f and f.stem,frames=f and f.sourceFrames}) end
end
elseif r.faintReturn then
local ok=R.updateFaint(P.session,r,dt)
if V.FxDiagnostics then pcall(V.FxDiagnostics.sample,r.faintReturn,'faint.tick',{battler=r.battlerId,ok=ok,
error=r.faintReturn.error,modulation=r.faintReturn.modulation,age=r.faintReturn.age,
hidden=R.faintActorVisible(r.faintReturn,'player')==false},.2) end
if not ok then
P.faintError=r.faintReturn.error or 'Source faint-return failed'
R.finishFaint(r.faintReturn,r.faintReturn.context,{player=r},'runtime-error')
r.faintReturn=nil;pending.sourceFailed=true
end
end
local done=r.faintReturn and R.faintComplete(r.faintReturn)
or (pending.sourceFailed and a:terminalComplete())
if not done then return end
P.lastFaint={dex=r.dex,bodyAge=a.faintAge,clipClock=a.clipClock,duration=a:stateDuration('faint'),
sourceAge=r.faintReturn and r.faintReturn.age,sourceFailed=pending.sourceFailed}
local Anim=req('src.core.game3.battle.anim');local pres=Anim.present(r.battlerId)
local stage=Anim.stage();local hb=stage and stage.healthbox and stage.healthbox[r.battlerId]
if pres then pres.visible=false;pres.oy=0 end
if hb then hb.visible=false end
r.visible=false;r.faintedVisual=true
clearFaint(r,'source-faint-complete')
P.faintCompletions=(P.faintCompletions or 0)+1
P.notify('battle.presentation_faint_complete','passive',r.battlerId,r.battlerId)
if pending.onComplete then pending.onComplete() end
end
function P.finish()
P.pendingMove=nil
P.multiHit=nil
if P.session then V.DoublesMovePresentation.finish(P.session) end
if P.session and V.FxDiagnostics then pcall(V.FxDiagnostics.note,'battle.finish',{sourceMoves=P.sourceOwned,nativeFallbacks=P.nativeFallbacks,faintError=P.faintError});pcall(V.FxDiagnostics.flush,true) end
for _,r in pairs(P.records) do clearFaint(r,'battle-finish');call(r.actor,'release') end
P.records={};P.session=nil
end
function P.begin(ctx)
P.finish()
P.session={generation=3,screen=ctx.battle,context=ctx,actors=P.records,core={slots={}}}
if V.FxDiagnostics then pcall(V.FxDiagnostics.battleStart,ctx) end
return true
end
function P.update(ctx,dt,readinessOnly)
if not P.session then P.begin(ctx) end
P.clock=P.clock+(dt or 0)
P.session.context=ctx
local facade=V.Gen3Runtime.sync(ctx.battle)
local models=V.BattleSettings.pokemonModelsEnabled(ctx.game)
for id=0,3 do
local b=facade.battlers[id]
local old=P.records[id]

local mon=b and b.mon
local visual=mon
local pres=b and b.presentation
local species=pres and pres.transformSpecies or (b and b.native and b.native.species)
if mon and species and species~=mon.species then
if old and old.mon==mon and old.visual and old.visual~=mon and old.visual.species==species then visual=old.visual
else visual=setmetatable({species=species,speciesNumbering='internal'},{__index=mon}) end
end
local dex,variant
if visual then dex,variant=V.ModelIdentity.resolve(ctx.game,visual) end
local NativeP=req('src.core.game3.pokemon');local Ui=req('src.core.game3.battle.ui')
local form=dex==351 and Ui.castformForm(id,b.native) or 0
if dex==351 then variant=V.ColosseumDex.withForm(variant,form) end


local nativeForm=dex==201 or dex==386 or (pres and pres.substitute)
local revived=old and old.faintedVisual and b and not b.fainted and not b.absent and pres and pres.visible
if old and (revived or old.mon~=mon or old.dex~=dex or old.variant~=variant or ((not models or nativeForm) and old.actor)) then
clearFaint(old,'occupant-replaced');call(old.actor,'release');P.records[id]=nil;old=nil
end
if b and (not b.absent or (old and old.pendingFaint)) then
local r=old or {battlerId=id,slot=SLOT[id],mon=mon,dex=dex,variant=variant}
P.records[id]=r;r.battler=b;r.visible=b.visible;r.presentation=pres;r.visual=visual
if r.pendingFaint then r.visible=true elseif r.faintedVisual then r.visible=false end
r.nativeForm=nativeForm
r.modelsRequired=models and not nativeForm
local picSp,shiny,personality=Ui.picArgs(b.native,species or NativeP.speciesOf(mon))


if dex==351 then r.sourceModelId=V.ColosseumSpeciesIndex and V.ColosseumSpeciesIndex.castformModelForForm(form)
else r.sourceModelId=nil end
local substitute=pres and pres.substitute
if not r.spriteInitialized or r.spriteSpecies~=picSp or r.spriteShiny~=shiny
or r.spritePersonality~=personality or r.spriteForm~=form or r.spriteSubstitute~=substitute then
local pic=NativeP.frontPic(picSp,form,shiny,personality)
r.sprite=pres and pres.substitute and req('src.core.game3.battle.anim').substituteImage(id) or (pic and pic.image)
r.spriteSpecies=picSp;r.spriteShiny=shiny;r.spritePersonality=personality
r.spriteForm=form;r.spriteSubstitute=substitute;r.spriteInitialized=true
end
local slot=P.session.core.slots[SLOT[id]] or {id=SLOT[id]}
slot.mon=mon;slot.battler=b;slot.battlerId=id;P.session.core.slots[SLOT[id]]=slot
r.readyBattler=r.readyBattler or {};r.readyBattler.mon=visual or mon;r.readyBattler._cbeCastformForm=dex==351 and form or nil
if models and not nativeForm and dex and not r.actor and P.clock>=(r.retryAt or 0) then


local ready=not V.PokemonActors.peek or V.PokemonActors.peek('cbe-gen3',dex,variant).resident
if ready then
r.actor,r.error=V.PokemonActors.acquireCached('cbe-gen3',dex,variant,
{context=ctx,battler=r.readyBattler,side=b.side,noSource=true,allowStorageBattleBody=true})
end
r.retryAt=r.actor and nil or P.clock+.016
if r.actor then call(r.actor,'spawn',1);call(r.actor,'idle')
else V.PokemonActors.queueBattlePrewarm(facade,SLOT[id],r.readyBattler,true) end
end
local MP,TP=V.DoublesMovePresentation,V.TrainerPerformance
local actorDt=MP.actorDt and MP.actorDt(P.session,r,dt)
or (TP and TP.pokemonDt and TP.pokemonDt(ctx,dt,r.actor) or dt)
if r.pendingFaint and MP.presentationDt then actorDt=MP.presentationDt(P.session,dt) end
if not readinessOnly then
call(r.actor,'update',actorDt)
updateFaint(r,actorDt)
end
else
if old then clearFaint(old,'slot-cleared');call(old.actor,'release');P.records[id]=nil end
local slot=P.session.core.slots[SLOT[id]] or {id=SLOT[id]}
slot.mon=nil;slot.battler=nil;slot.battlerId=nil;P.session.core.slots[SLOT[id]]=slot
end
end


if readinessOnly then return end
if P.session.movePresentation then V.DoublesMovePresentation.update(P.session,dt) end
local pending=P.pendingMove
if pending and pending.sourceFailureReason then P.failSourceMove(pending.event,pending.sourceFailureReason) end
P.completeMove()
if V.FxDiagnostics then pcall(V.FxDiagnostics.flush) end
end
function P.refresh(ctx) return P.update(ctx,0,true) end
function P.anchor(ctx,id)
local side=id%2==0 and 'player' or 'enemy'
local a=ctx.arena and ctx.arena[side]
local b=ctx.arena and ctx.arena[side=='player' and 'enemy' or 'player']
if not a or not b then return end
if ctx.battle.double then return V.DoublesPresenter.actorAnchor(ctx,SLOT[id]) end
return a[1],a[2],b[1]-a[1],b[2]-a[2]
end
function P.draw(ctx)
local api=V.PokemonActors.service
local sv=ctx.services or {};local vp=api.worldUnits and sv.stageVP or sv.vp
if not vp then return false end
local g=love.graphics
local jobs={}
for id=0,3 do local r=P.records[id]
local captureScale=V.Gen3Capture and V.Gen3Capture.scale(id) or 1
if r and r.visible and captureScale>.015 and V.DoublesMovePresentation.visible(P.session,r)
and (not V.ReleasePresentation or V.ReleasePresentation.faintActorVisible(r.faintReturn,'player')~=false) then
local x,z,dx,dz=P.anchor(ctx,id)
if x and r.actor then
local scale=(r.presentation and r.presentation.scale or 1)*captureScale
call(r.actor,'spawn',math.max(.01,math.min(1,scale)))
jobs[#jobs+1]={r=r,matrix=r.actor:matrix(x,ctx.groundY or 0,z,dx,dz)}
elseif x and r.sprite and sv.project and (not r.modelsRequired or V.Gen3Runtime.nativeModelFallback) then
local px,py=sv.project(x,ctx.groundY or 0,z)
if px and py then
local image=r.sprite;local iw,ih=image:getDimensions()
local scale=math.max(24,(sv.renderSize.height or 600)*.14)/ih*captureScale
g.push('all');g.setShader();g.setDepthMode();g.setColor(1,1,1,1)
g.draw(image,px,py,0,scale,scale,iw/2,ih);g.pop()
end
end
end
end
if #jobs>0 then api.withRenderer(vp,function()
for _,job in ipairs(jobs) do job.r.actor:draw(job.matrix) end
return true
end,{eye=sv.camera and sv.camera.pose.eye,focus=sv.camera and sv.camera.pose.focus,
width=sv.renderSize and sv.renderSize.width,height=sv.renderSize and sv.renderSize.height,context=ctx}) end
if P.session.movePresentation then V.DoublesMovePresentation.draw(P.session,ctx) end
if V.ReleasePresentation then for _,r in pairs(P.records) do
if r.faintReturn then V.ReleasePresentation.drawFaint(P.session,r,ctx) end
end end
return true
end
function P.readiness()
local missing,errorMessage=0,nil
for _,r in pairs(P.records) do
local A=V.PokemonActors
r.readyBattler=r.readyBattler or {};r.readyBattler.mon=r.visual or r.mon
local needsActions=r.actor and V.MoveFXExtractor and A.requiredModelReady
and not A.requiredModelReady(r.dex,r.variant,P.session.context.game,r.readyBattler)
if r.modelsRequired and (not r.actor or needsActions) then
if needsActions then A.queueBattlePrewarm(P.session.screen,r.slot,r.readyBattler,true) end
missing=missing+1
local failure=V.PokemonActors.battlePreparationFailure and V.PokemonActors.battlePreparationFailure(r.dex,r.variant)
if failure then errorMessage=tostring(failure.reason) end
end
end
return missing==0,missing,errorMessage
end



local function impactsFor(event)
local seq=req('src.core.game3.battle.anim_seq')
local steps=seq._steps;local index=seq._i or 1
if not (steps and steps[index] and steps[index].kind=='move'
and steps[index].data.moveId==event.move) then return {} end
local out={};local i=index+1;local seen={}
while steps[i] and steps[i].kind=='hitfx' and steps[i+1] and steps[i+1].kind=='hp' do
local hit,hp=steps[i],steps[i+1];local d=hp.data
local id=d.battler or req('src.core.game3.battle.anim').idOf(d.side)

if id==nil or seen[id] or id==event.battlerId or not P.records[id]
or not tonumber(d.from) or not tonumber(d.to) or d.to>=d.from then break end
seen[id]=true
out[#out+1]={kind='damage',eventId=tostring(event.eventId)..':'..i,impactOf=event.eventId,
sourceSlot=event.slot,sourceBattlerId=event.battlerId,slot=SLOT[id],battlerId=id,
move=event.move,moveDef=event.moveDef,amount=d.from-d.to,hp=d.to,
nativeHit=hit,nativeHp=hp,nativeSteps=steps}
i=i+2
end
return out
end
function P.presentImpact(e)
local pending=P.pendingMove
local seq=req('src.core.game3.battle.anim_seq')
if not pending or e.impactOf~=pending.event.eventId or seq._steps~=e.nativeSteps
or e.presentationConsumed then return false end
local d=e.nativeHp.data


e.nativeHit.kind='cbe_source_presented';e.nativeHp.kind='cbe_source_presented'
e.presentationConsumed=true;pending.hpPending=pending.hpPending+1
P.nativeHp(e.battlerId,d.from,d.to,d.maxHp,{onComplete=function()
pending.hpPending=math.max(0,pending.hpPending-1)
end})
P.notify('battle.presentation_damage','damage',e.sourceBattlerId,e.battlerId,e.move,e.moveDef)
return true
end
function P.completeMove()
local pending=P.pendingMove
if not pending then return end
local seq=req('src.core.game3.battle.anim_seq')
if pending.steps and seq._steps~=pending.steps then
P.pendingMove=nil
if P.session then V.DoublesMovePresentation.finish(P.session) end
return
end
if not pending.nativeDone or pending.hpPending>0 or (P.session and P.session.movePresentation) then return end
P.pendingMove=nil
if pending.onEnd then pending.onEnd() end
end
function P.failSourceMove(e,reason)
local pending=P.pendingMove
if not (pending and pending.event==e and pending.sourceOwned and P.nativeMove) then return false end
pending.sourceOwned=false;pending.nativeDone=false;pending.sourceFailureReason=nil
P.multiHit=nil
e.sourceOwned=false;e.cbeNativeFallback=true
P.sourceOwned=math.max(0,(P.sourceOwned or 0)-1)
P.nativeFallbacks=(P.nativeFallbacks or 0)+1
if V.FxDiagnostics then pcall(V.FxDiagnostics.note,'move.source_failed',{move=e.move,why=reason}) end
local opts={};for k,v in pairs(pending.nativeOpts or {}) do opts[k]=v end
opts.onEnd=function() pending.nativeDone=true end
local result=P.nativeMove(e.move,opts)
if P.nativeBusy and not P.nativeBusy() then pending.nativeDone=true end
return result~=false
end
function P.queueSourceFailure(ctx,moveId,reason)
local pending=P.pendingMove
local battle=ctx and ctx.battle
if not (P.session and pending and pending.sourceOwned and
(not battle or P.session.screen==battle) and tonumber(pending.event.move)==tonumber(moveId)) then return false end
pending.sourceFailureReason=tostring(reason or 'source visual playback failed')


pending.nativeDone=false
return true
end
function P.move(move,opts)
if not P.session then return end
opts=opts or {}
local Anim=req('src.core.game3.battle.anim')
local a=opts.attackerId or Anim.idOf(opts.attackerSide) or 0
local t=opts.targetId or Anim.idOf(opts.targetSide) or 1
if not P.records[a] or not P.records[t] then return end
local def=req('src.core.game3.battle.moves').get(move)
if tonumber(def and def.effect)==155 and (tonumber(opts.moveTurn) or 0)>0 then
local pres=Anim.present(a);pres.visible=true;pres.invisible=nil;pres.battlerInvisible=nil
end
P.notify('battle.presentation_move','attack',a,t,move,def)
P.serial=(P.serial or 0)+1
local e={kind='move',eventId=P.serial,slot=SLOT[a],target=SLOT[t],
targets={SLOT[t]},battlerId=a,targetBattlers={[SLOT[t]]=t},move=move,moveDef=def,
statusMove=(tonumber(def and def.power)==0) or (def and tostring(def.category or ''):lower()=='status')}
e.impacts=impactsFor(e)
for _,impact in ipairs(e.impacts) do
if not e.targetBattlers[impact.slot] then
e.targets[#e.targets+1]=impact.slot;e.targetBattlers[impact.slot]=impact.battlerId
end
end
local charge={[39]=true,[75]=true,[145]=true,[151]=true,[155]=true}
local user=P.records[a].battler.native
if charge[tonumber(def and def.effect)] and (tonumber(opts.moveTurn) or 0)==0
and user and user.twoTurnMove and #e.impacts==0 then e.stage='charge' end
P.session.core.presentImpact=function(_,impact) return P.presentImpact(impact) end
V.DoublesMovePresentation.begin(P.session,e)
return e
end
function P.notify(event,phase,source,target,move,def)
if not P.session then return end
local ctx=P.session.context
P.session.cameraTarget=(phase=='attack') and source or target
ctx.phase=phase;ctx.progress=0
local a=P.records[source];local b=P.records[target]
local payload={battle=ctx.battle,user=a and a.battler,target=b and b.battler,
side=source%2==0 and 'player' or 'enemy',move=move,moveDef=def}
if V.Camera and V.Camera.event then pcall(V.Camera.event,V.Camera,ctx,event,payload) end
for _,trainer in ipairs({V.PlayerTrainer,V.Trainer}) do
if trainer and trainer.event then pcall(trainer.event,trainer,ctx,event,payload) end
end
end
function P.install()
if P.installed then return end
local C=V.CurrentSpriteModels
for name,fn in pairs({begin=P.begin,update=P.update,drawWorld=P.draw,finish=P.finish}) do
local native=C[name]
C[name]=function(self,ctx,...)
if ctx and ctx.battle and ctx.battle.__cbeGeneration==3 then return fn(ctx,...) end
return native(self,ctx,...)
end
end
local A=req('src.core.game3.battle.anim')
local move,faint,hp,busy=A.launchMove,A.faintMon,A.tweenHp,A.busy
P.nativeHp=hp;P.nativeMove=move;P.nativeBusy=busy
A.busy=function() return P.pendingMove~=nil or P.faintActive()~=nil or busy() end
A.launchMove=function(id,opts)
opts=opts or {}
if A._headless or not P.session then return move(id,opts) end
local seq=req('src.core.game3.battle.anim_seq')
local turn=tonumber(opts.moveTurn) or 0
local action=P.multiHit




if action and turn==action.turn+1 and action.steps==seq._steps
and action.move==id and action.attacker==opts.attackerId and action.target==opts.targetId then
action.turn=turn
action.pendingHp=true
P.multiHitContinuations=(P.multiHitContinuations or 0)+1
if opts.onEnd then opts.onEnd() end
return true
end
P.multiHit=nil
local e=P.move(id,opts)
if not (e and P.session.movePresentation) then return move(id,opts) end
local pending={event=e,onEnd=opts.onEnd,nativeOpts=opts,hpPending=0,steps=seq._steps}
P.pendingMove=pending
local E,W=V.MoveFXExtractor,V.WazaSequenceRuntime
local spec=E and E.peek(id,e.moveDef)
if spec and V.WazaPhasePolicy then
spec=V.WazaPhasePolicy.select(spec,{moveId=id,dex=P.records[e.battlerId].dex,
sourceModelId=P.records[e.battlerId].sourceModelId,stage=e.stage or 'attack',statusMove=e.statusMove==true})
end


local sourceOwns,ownership=sourceOwnership(spec,e,id)
if V.FxDiagnostics then
local why=nil;if not spec and E then why=select(2,E.peek(id,e.moveDef)) end
pcall(V.FxDiagnostics.note,'move.launch',{move=id,stem=spec and spec.stem,peek=spec and 'ok' or why,canOwn=ownership.canOwn,
audioReady=ownership.audioReady,attackVisual=ownership.attackVisual,receivingVisual=ownership.receivingVisual,
sourceOwns=sourceOwns and true or false,stage=e.stage or 'attack',attacker=e.battlerId,target=opts.targetId or opts.targetSide})
end
if sourceOwns then
e.sourceOwned=true
pending.nativeDone=true;pending.sourceOwned=true
P.sourceOwned=(P.sourceOwned or 0)+1
local effect=tonumber(e.moveDef and e.moveDef.effect)
if turn==0 and (effect==29 or effect==44 or effect==77 or effect==104
or type(e.moveDef and e.moveDef.hits)=='table' or (tonumber(e.moveDef and e.moveDef.hits) or 0)>1) then
P.multiHit={steps=seq._steps,move=id,attacker=opts.attackerId,target=opts.targetId,turn=0}
end
return true
end
P.nativeFallbacks=(P.nativeFallbacks or 0)+1
e.cbeNativeFallback=true
local nativeOpts={};for k,v in pairs(opts) do nativeOpts[k]=v end
nativeOpts.onEnd=function() pending.nativeDone=true end
local result=move(id,nativeOpts)
if not busy() then pending.nativeDone=true end
return result
end
A.faintMon=function(key,opts)
local id=A.idOf(key) or 1
if not A._headless and P.faint(id,opts) then return true end
return faint(key,opts)
end
A.tweenHp=function(key,from,to,max,opts)
local id=A.idOf(key) or 1
local r=P.records[id]
local action=P.multiHit
local seq=req('src.core.game3.battle.anim_seq')
local continuation=action and action.pendingHp and action.steps==seq._steps and action.target==id
if continuation then action.pendingHp=nil end



if r and to<from and not continuation then
call(r.actor,'hit',{damage=from-to,target={hp=to}},{deferFaint=true})
P.notify('battle.presentation_damage','damage',id,id)
end
return hp(key,from,to,max,opts)
end
local anchor=V.DoublesPresenter.actorAnchor
V.DoublesPresenter.actorAnchor=function(ctx,id)
if ctx.battle and ctx.battle.__cbeGeneration==3 and not ctx.battle.double then
for n,slot in pairs(SLOT) do if slot==id then return P.anchor(ctx,n) end end
end
return anchor(ctx,id)
end
P.installed=true
end
function P.status()
local ready,total,slots=0,0,{}
for id,r in pairs(P.records) do
total=total+1;if r.actor then ready=ready+1 end
slots[id]={dex=r.dex,variant=r.variant,model=r.actor~=nil,nativeForm=r.nativeForm,error=r.actor and nil or r.error}
end
return {actors=ready,slots=total,streaming=ready<total,battlers=slots,
sourceMoves=P.sourceOwned or 0,nativeMoveFallbacks=P.nativeFallbacks or 0,movePending=P.pendingMove~=nil,
multiHitContinuations=P.multiHitContinuations or 0,
faintPending=P.faintActive()~=nil,faintCompletions=P.faintCompletions or 0,faintError=P.faintError}
end
return P
