




local V=...
local req=V.engineRequire or require
local C={serial=0}
local unpack=table.unpack or unpack
local function pack(...)return {n=select('#',...),...}end
local SLOT={[0]='player-left',[1]='enemy-left',[2]='player-right',[3]='enemy-right'}
local SEND={opponent_sendout='enemy',player_throw='player',sendout_player='player',sendout_enemy='enemy'}
local TAIL={shiny_check=true,cry=true,healthbox=true,mon_anim=true,mon_anim_wait=true,undarken=true}
local function session()
local s=V.Gen3Presentation and V.Gen3Presentation.session
if not (s and s.context and s.context.battle) then return end
return s
end
local function enabled(s)
if not s then return false end
local battle=s.context.battle
local st=battle and battle._model
if not (battle and battle.double) or (st and (st.safari or st.pokedude or st.oldManTutorial
or st.ghostBattle or (st.kinds and st.kinds.tutorial)))then return false end
local settings=V.BattleSettings
if settings and (not settings.pokemonModelsEnabled(s.context.game)
or settings.prefs(s.context.game).arenasEnabled==false
or (settings.cameraEnabled and not settings.cameraEnabled(s.context.game))) then return false end
return true
end
local function scoped(s,fn,...)
if not fn then return end
local previous=C.tweenScope;C.tweenScope=s
local out=pack(pcall(fn,...));C.tweenScope=previous
if not out[1] then error(out[2],0)end
return unpack(out,2,out.n)
end
local function idOf(key)
if type(key)=='number' then return SLOT[key] and key end
return key=='player' and 0 or key=='enemy' and 1 or nil
end
function C.observe(seq)
local s=session();if not enabled(s) then return end
local step=seq._steps and seq._steps[seq._i or 1]
if not step then return end
local d=step.data or {};local side=SEND[step.kind]
local recall=step.kind=='withdraw' or step.kind=='switch_out'
if not side and not recall then
if step.kind=='move' or step.kind=='faint' then s.deploymentCamera=nil end
return
end
if s.deploymentCamera and s.deploymentCamera.step==step then return end
local ids={}
for _,key in ipairs(d.ids or {d.id~=nil and d.id or d.battler~=nil and d.battler or d.side or side}) do
local id=idOf(key)
if id~=nil then ids[#ids+1]=id end
end
if #ids==0 then return end
C.serial=C.serial+1
s.deploymentCamera={serial=C.serial,step=step,steps=seq._steps,seq=seq,ids=ids,
kind=recall and 'recall' or 'send',phase=recall and 'recall' or 'trainer-throw',
index=1,age=0,revealAge=0,startClock=s.deploymentClock or 0,
side=side or (ids[1]%2==0 and 'player' or 'enemy')}
end
function C.tick(s,dt)
if not s then return end
local rate=V.BattleTempo and V.BattleTempo.presentationRate(s.context.game)or 1
s.deploymentClock=(s.deploymentClock or 0)+math.max(0,tonumber(dt)or 0)*rate
end
function C.update(s,dt)
if not s then return end
if not (V.FrameWork and V.FrameWork.attached(s.context.game))then C.tick(s,dt)end
local d=s.deploymentCamera;if not d then return end
if s.movePresentation or (V.Gen3Presentation and V.Gen3Presentation.faintActive()) then
s.deploymentCamera=nil;return
end
local B=req('src.core.game3.battle')
if B._phase=='command' or not B.isActive() then s.deploymentCamera=nil;return end
local step=d.seq._steps and d.seq._steps[d.seq._i or 1]
if d.seq._steps~=d.steps or (step and step~=d.step and not TAIL[step.kind]
and step.kind~='msg' and step.kind~='pause') then s.deploymentCamera=nil;return end
local clock=s.deploymentClock or 0
d.age=math.max(0,clock-d.startClock)
local records=V.Gen3Presentation.records
if d.kind=='send' then
local anyVisible=false
for _,id in ipairs(d.ids)do local r=records[id]
if r and r.visible and not r.faintedVisual then anyVisible=true end
end
if anyVisible and d.phase=='trainer-throw' then
d.phase='sendout-reveal';d.revealStart=clock;d.revealAge=0
end
if d.phase=='sendout-reveal' then
d.revealAge=math.max(0,clock-(d.revealStart or clock))
d.index=math.min(#d.ids,1+math.floor(d.revealAge/.72))
end
end
local r=records[d.ids[d.index]]


if r and (d.record~=r or d.actor~=r.actor)then d.record=r;d.actor=r.actor;d.subject=nil end
if r and not d.subject and V.Gen3BattleCamera then
d.subject=V.Gen3BattleCamera.subject(s.context,r,true)
end
end
function C.pose(base,s,ctx)
local d=s and s.deploymentCamera
if not enabled(s)or not d or not d.subject then return end
local camera=V.Camera
if camera then
local manual
if type(camera.isManual)=='function' then manual=camera:isManual()
elseif type(camera.status)=='function' then manual=camera:status().manual end
if manual then return end
end
local pose,phase=nil,d.phase
if phase=='trainer-throw' then
if V.Camera then
local paired=d.side=='enemy' and (ctx.battle.trainerB or ctx.battle.__cbeTrainerPairPresentation)
pose=not paired and V.Camera:sendoutShot(ctx,ctx.arena,d.side)
or V.Camera:trainerDeploymentShot(ctx,ctx.arena,d.side,d.ids[d.index])
end
if pose and V.Gen3BattleCamera then
pose=V.Gen3BattleCamera.fit(ctx,pose,'passive',nil,'deployment:'..d.serial..':trainer',
{trainerSide=d.side,trainerId=d.ids[d.index],trainerIds=d.ids})
end
else
local subject=d.subject
pose=V.DoublesCamera.deploymentPose(base,ctx,subject.center,subject.height,SLOT[d.ids[d.index]])
if V.Camera then pose=V.Camera:guardDeploymentPose(pose,ctx.arena)end
if V.Gen3BattleCamera then
pose=V.Gen3BattleCamera.fit(ctx,pose,'deployment',d.ids[d.index],
'deployment:'..d.serial..':'..d.index,{deployment=true,subject=subject})
end
end
if pose then
C.last={phase=phase,battlerId=d.ids[d.index],ids=d.ids,serial=d.serial,
sourceRetailExact=false,eye=pose.eye,focus=pose.focus}
return pose
end
end
function C.install()
if C.installed then return end
local Anim=req('src.core.game3.battle.anim');local nativeTween=Anim.tweenStage
local Task=req('src.core.game3.task')
Anim.tweenStage=function(frames,onStep,onComplete)
local s=C.tweenScope or session()
local seq=C.activeSequence
local step=seq and seq._steps and seq._steps[seq._i or 1]
local deployment=step and (SEND[step.kind] or step.kind=='withdraw')
if not s or Anim._headless or not (C.tweenScope or (enabled(s)and deployment)) then
return nativeTween(frames,onStep,onComplete)
end
if seq then C.observe(seq)end
frames=math.max(1,tonumber(frames)or 1)
local start=s.deploymentClock or 0;local lastFrame=-1;local t
Anim._introTweening=(Anim._introTweening or 0)+1
t=Task.spawn(function(task)
if session()~=s then return true end
local frame=math.min(frames,math.floor(((s.deploymentClock or 0)-start)*60+1e-6))
task.frames=frame



if frame~=lastFrame then
local first=lastFrame<0 and math.min(1,frame)or lastFrame+1
for sample=first,frame do
task.frames=sample
scoped(s,onStep,sample/frames,task)
if session()~=s then return true end
end
lastFrame=frame
end
return frame>=frames
end,{onDone=function()
if session()~=s then return end
Anim._stageTasks[t.id]=nil
Anim._introTweening=math.max(0,(Anim._introTweening or 1)-1)
scoped(s,onComplete)
end})
Anim._stageTasks[t.id]=true
return t
end
for _,name in ipairs{'intro_seq','switch_seq','anim_seq'}do
local seq=req('src.core.game3.battle.'..name);local update=seq.update
seq.update=function(...)
C.observe(seq)
local s=session();local d=s and s.deploymentCamera
local step=seq._steps and seq._steps[seq._i or 1]
if enabled(s)and d and d.seq==seq and d.kind=='send' and d.phase=='sendout-reveal'
and step~=d.step and d.revealAge<#d.ids*.72 then return false end
local previous=C.activeSequence;C.activeSequence=seq
local out=pack(pcall(update,...));C.activeSequence=previous
if not out[1] then error(out[2],0)end



C.observe(seq)
return unpack(out,2,out.n)
end
end
C.installed=true
end
C._test={slot=SLOT}
return C
