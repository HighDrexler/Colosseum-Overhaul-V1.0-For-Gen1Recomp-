local V=...
local R={installed=false,activeBattle=nil,pendingEnd=nil,pendingEndReason=nil,pendingEndSince=nil,finishWrapper=nil,
captureSoundWrapper=nil,captureSoundInner=nil,captureSoundBridge=false,nativeCaughtSuppressed=0,
movePlayWrapper=nil,movePlayInner=nil,stereoWrapper=nil,stereoInner=nil,moveSoundBridge=false,nativeMoveSoundsSuppressed=0,
modelPrewarm=nil,entryTiming=nil,exitTiming=nil}

local mod=V.mod
local ArenaCatalog=V.ArenaCatalog
local Arena=V.Arena
local BattleArtBridge=V.BattleArtBridge
local Camera=V.Camera
local CurrentSpriteModels=V.CurrentSpriteModels
local PokemonActors=V.PokemonActors
local NativeTrainerSprites=V.NativeTrainerSprites
local PlayerTrainer=V.PlayerTrainer
local StandaloneHost=V.StandaloneHost
local StadiumBridge=V.StadiumBridge
local Trainer=V.Trainer
local Compat=V.GenerationCompat
local BattleDirector=V.BattleDirector
local MoveFXOwnership=V.MoveFXOwnership
local BattleSides=V.BattleSides
local WazaHandlers=V.WazaHandlers
local MoveFXExtractor=V.MoveFXExtractor
local ResidentPrewarm=V.ResidentPrewarm
local FrameWork=V.FrameWork

local function platformOS()
if love and love.system and type(love.system.getOS)=="function" then
local ok,v=pcall(love.system.getOS);if ok and v then return tostring(v) end
end
return "Unknown"
end
local PLATFORM_OS=platformOS()
local ANDROID_RUNTIME=PLATFORM_OS=="Android"
local MOBILE_RUNTIME=ANDROID_RUNTIME or PLATFORM_OS=="iOS"
local androidActionWarmNextAt=0
local androidGcNextAt=0
local function wallNow()
if love and love.timer and type(love.timer.getTime)=="function" then
local ok,v=pcall(love.timer.getTime);if ok and type(v)=="number" then return v end
end
return os.clock()
end
local function stackTop(game)
local stack=game and game.stack
if stack and type(stack.top)=="function" then
local ok,v=pcall(stack.top,stack);if ok then return v end
end
return nil
end







local function mobileSinglesPrewarmSafe(battle)
if type(battle)~="table" then return false end
if battle.enemySendingOut or battle.sendingOut or battle.growIn or battle.shrinkOut then return false end
if battle.current or battle.waitingUI or battle.waitingSound or battle.animPlaying or battle.draining then return false end
return true
end

local SEMANTIC_EVENTS={
"battle.turn_started",
"battle.move_used",
"battle.damage_dealt",
"battle.status_inflicted",
"battle.ball_thrown",
"battle.battler_switched",
"battle.fainted",
"battle.exp_gained",
"battle.turn_ended",
}

local function contextFor(battle)
battle=Compat and Compat.prepare(battle) or battle
return {battle=battle,game=(battle and battle.game) or mod.game}
end


local unpackArgs=table.unpack or unpack
local function installCaptureSoundBridge()
local req=V.engineRequire or require
local ok,Sound=pcall(req,"src.core.Sound")
if not ok or type(Sound)~="table" or type(Sound.play)~="function" then
R.captureSoundBridge=false
return false
end
if Sound.play==R.captureSoundWrapper then R.captureSoundBridge=true;return true end
local inner=Sound.play
R.captureSoundInner=inner
R.captureSoundWrapper=function(...)
local args={...}
local requested



for i=1,math.min(3,#args) do
if type(args[i])=="string" and args[i]=="Caught_Mon" then requested=args[i];break end
end
if requested=="Caught_Mon" and R.activeBattle and PlayerTrainer
and type(PlayerTrainer.suppressesNativeCaughtAudio)=="function" then
local okOwn,owned=pcall(PlayerTrainer.suppressesNativeCaughtAudio,PlayerTrainer,contextFor(R.activeBattle))
if okOwn and owned==true then
R.nativeCaughtSuppressed=(tonumber(R.nativeCaughtSuppressed) or 0)+1



return nil
end
end
return inner(unpackArgs(args,1,#args))
end
Sound.play=R.captureSoundWrapper
R.captureSoundBridge=true

local function sourceMoveAudioOwned()
if not (R.activeBattle and MoveFXOwnership and type(MoveFXOwnership.ownsNativeAudio)=="function") then return false end
local okOwn,owned=pcall(MoveFXOwnership.ownsNativeAudio,MoveFXOwnership,R.activeBattle)
return okOwn and owned==true
end




if type(Sound.playMove)=="function" and Sound.playMove~=R.movePlayWrapper then
local innerMove=Sound.playMove;R.movePlayInner=innerMove
R.movePlayWrapper=function(...)
if sourceMoveAudioOwned() then R.nativeMoveSoundsSuppressed=(R.nativeMoveSoundsSuppressed or 0)+1;return nil end
return innerMove(...)
end
Sound.playMove=R.movePlayWrapper
end
if type(Sound.playStereo)=="function" and Sound.playStereo~=R.stereoWrapper then
local innerStereo=Sound.playStereo;R.stereoInner=innerStereo
R.stereoWrapper=function(...)
if sourceMoveAudioOwned() then R.nativeMoveSoundsSuppressed=(R.nativeMoveSoundsSuppressed or 0)+1;return nil end
return innerStereo(...)
end
Sound.playStereo=R.stereoWrapper
end
R.moveSoundBridge=(Sound.playMove==R.movePlayWrapper) or (Sound.playStereo==R.stereoWrapper)
return true
end

local function dispatch(name,payload)
local battle=(type(payload)=="table" and payload.battle) or R.activeBattle
battle=Compat and Compat.prepare(battle) or battle
local ctx=contextFor(battle)




if name=="battle.battler_switched" and PokemonActors and type(PokemonActors.prewarmSwitch)=="function" then
local side
if BattleSides and type(BattleSides.payload)=="function" then
local okSide,value=pcall(BattleSides.payload,ctx,payload,{"side","battler","replacement","newBattler","target"})
if okSide then side=value end
end
if not side and type(payload)=="table" then side=payload.side or payload.targetSide end
if BattleSides and type(BattleSides.value)=="function" then side=BattleSides.value(side) or side end
local replacement=type(payload)=="table" and (payload.replacement or payload.newBattler or payload.battler or payload.target) or nil
if side then
pcall(PokemonActors.prewarmSwitch,battle,side,replacement,
{allowExtract=false,deferCold=true})
end
end
if BattleDirector and type(BattleDirector.event)=="function" then
pcall(BattleDirector.event,BattleDirector,ctx,name,payload)
end
if MoveFXOwnership and type(MoveFXOwnership.event)=="function" then
pcall(MoveFXOwnership.event,MoveFXOwnership,ctx,name,payload)
end
if StandaloneHost then StandaloneHost.event(name,payload) end





local standaloneActive=false
if StandaloneHost and type(StandaloneHost.status)=="function" then
local ok,status=pcall(StandaloneHost.status)
standaloneActive=ok and type(status)=="table" and status.active==true
end
if not standaloneActive and CurrentSpriteModels and type(CurrentSpriteModels.event)=="function" then
pcall(CurrentSpriteModels.event,CurrentSpriteModels,ctx,name,payload)
end




if name=="battle.ball_thrown" and Camera and StadiumBridge and StadiumBridge.usesCamera(battle) then
pcall(Camera.event,Camera,ctx,name,payload)
end

if PlayerTrainer and type(PlayerTrainer.event)=="function" then PlayerTrainer:event(ctx,name,payload) end
if Trainer and type(Trainer.event)=="function" then Trainer:event(ctx,name,payload) end
end

local function beginBattle(payload)
local battle=type(payload)=="table" and payload.battle or nil
battle=Compat and Compat.prepare(battle) or battle
if not battle then return end
local entryStart=wallNow()




if ArenaCatalog and ArenaCatalog.releaseBattle then ArenaCatalog.releaseBattle() end
if ResidentPrewarm and ResidentPrewarm.cancelViewer then ResidentPrewarm.cancelViewer() end
if PokemonActors and PokemonActors.cancelPartyPrewarm then PokemonActors.cancelPartyPrewarm() end
R.activeBattle=battle
R.pendingEnd=nil
if MOBILE_RUNTIME then androidActionWarmNextAt=wallNow() end


installCaptureSoundBridge()
if BattleDirector and type(BattleDirector.begin)=="function" then
pcall(BattleDirector.begin,BattleDirector,contextFor(battle))
end
if MoveFXOwnership and type(MoveFXOwnership.begin)=="function" then
pcall(MoveFXOwnership.begin,MoveFXOwnership,contextFor(battle))
end

if not StandaloneHost then return end
if StadiumBridge and type(StadiumBridge.refreshModelGates)=="function" then
pcall(StadiumBridge.refreshModelGates)
end
if BattleArtBridge and type(BattleArtBridge.install)=="function" then
pcall(BattleArtBridge.install)
end








pcall(StandaloneHost.install,true)












if StadiumBridge then StadiumBridge.setDelegated(false) end





local hostStart=wallNow()
local began=StandaloneHost.begin(battle)
local hostEnd=wallNow()




local modelStart=wallNow()
if began and PokemonActors and type(PokemonActors.prewarmBattle)=="function" then
local opts={allowExtract=false,deferCold=true}
local okWarm,result=pcall(PokemonActors.prewarmBattle,battle,opts)
if okWarm then R.modelPrewarm=result else R.modelPrewarm={failed=2,error=tostring(result)} end
else
R.modelPrewarm={ready=0,failed=0,deferred=0,hostUnavailable=not began}
end
local modelEnd=wallNow()
R.entryTiming={totalMs=math.max(0,(modelEnd-entryStart)*1000),modelMs=math.max(0,(modelEnd-modelStart)*1000),
hostMs=math.max(0,(hostEnd-hostStart)*1000),began=began and true or false,
androidDeferred=ANDROID_RUNTIME and true or false,mobileDeferred=MOBILE_RUNTIME and true or false}
if NativeTrainerSprites then
if began then NativeTrainerSprites:begin({battle=battle})
else


NativeTrainerSprites:finish({battle=battle})
end
end
end

local function finishPresentation(battle,reason)
local exitStart=wallNow()
battle=Compat and Compat.prepare(battle) or battle
local standaloneWasActive=false
if StandaloneHost and type(StandaloneHost.status)=="function" then
local ok,status=pcall(StandaloneHost.status)
standaloneWasActive=ok and type(status)=="table" and status.active==true
end
local hostFinishStart=wallNow()
if StandaloneHost then StandaloneHost.finish(reason or "battle.ended") end
if PokemonActors and type(PokemonActors.cancelBattlePrewarm)=="function" then
pcall(PokemonActors.cancelBattlePrewarm,"battle-ended")
end
local hostFinishEnd=wallNow()



if not standaloneWasActive and CurrentSpriteModels and type(CurrentSpriteModels.finish)=="function" then
pcall(CurrentSpriteModels.finish,CurrentSpriteModels,contextFor(battle),reason or "battle.ended")
end
if NativeTrainerSprites then NativeTrainerSprites:finish({battle=battle}) end
if ArenaCatalog and ArenaCatalog.releaseBattle then ArenaCatalog.releaseBattle(battle) end
if BattleDirector and type(BattleDirector.finish)=="function" then
pcall(BattleDirector.finish,BattleDirector,contextFor(battle),reason or "battle.ended")
end
if MoveFXOwnership and type(MoveFXOwnership.finish)=="function" then
pcall(MoveFXOwnership.finish,MoveFXOwnership,contextFor(battle),reason or "battle.ended")
end






local pokemonTrimMs,wazaTrimMs,randomPrimeMs=0,0,0
if MOBILE_RUNTIME then
if PokemonActors and type(PokemonActors.trimRuntimeMemory)=="function" then
local t0=wallNow()





pcall(PokemonActors.trimRuntimeMemory,{game=battle and battle.game,keepParty=6,keepRecent=3,softLimit=9})
pokemonTrimMs=math.max(0,(wallNow()-t0)*1000)
end





if WazaHandlers and type(WazaHandlers.trimRuntimeMemory)=="function" then
local t0=wallNow();pcall(WazaHandlers.trimRuntimeMemory);wazaTrimMs=math.max(0,(wallNow()-t0)*1000)
end






end








local game=battle and battle.game
if game and ArenaCatalog and type(ArenaCatalog.selected)=="function" and ArenaCatalog.selected(game)=="random"
and type(ArenaCatalog.primeRandom)=="function" then
local t0=wallNow();pcall(ArenaCatalog.primeRandom,game);randomPrimeMs=math.max(0,(wallNow()-t0)*1000)


if ResidentPrewarm and type(ResidentPrewarm.queueArena)=="function" then
pcall(ResidentPrewarm.queueArena,game,"post-battle-random")
end
end
R.exitTiming={totalMs=math.max(0,(wallNow()-exitStart)*1000),hostFinishMs=math.max(0,(hostFinishEnd-hostFinishStart)*1000),
pokemonTrimMs=pokemonTrimMs,wazaTrimMs=wazaTrimMs,randomPrimeMs=randomPrimeMs}
R.activeBattle=nil
R.pendingEnd=nil
R.pendingEndReason=nil
R.pendingEndSince=nil
end

local function endBattle(payload)
dispatch("battle.ended",payload)
local battle=(type(payload)=="table" and payload.battle) or R.activeBattle
battle=Compat and Compat.prepare(battle) or battle











R.pendingEnd=battle
R.pendingEndSince=wallNow()
R.pendingEndReason=(Compat and Compat.isGen2Battle(battle)) and "gen2.screen.finished" or "gen1.stack-exited"
end

local function installGen2FinishBoundary()
if not (Compat and Compat.current and Compat.current()==2) then return true end
local req=V.engineRequire or require
local ok,BattleState=pcall(req,"src.battle.BattleState")
if not ok or type(BattleState)~="table" or type(BattleState.finishBattle)~="function" then
return false
end
local boundary=type(BattleState.completeBattle)=="function" and "completeBattle" or "finishBattle"
if BattleState[boundary]==R.finishWrapper then return true end
local inner=BattleState[boundary]
R.finishWrapper=function(self,...)
local results={pcall(inner,self,...)}
local success=table.remove(results,1)
if not success then error(results[1],0) end
local battle=Compat and Compat.prepare(self) or self
local pending=R.pendingEnd
if pending and ((Compat and Compat.matches(pending,battle)) or pending==battle) then
finishPresentation(battle,"gen2.screen.finished")
end
return unpack(results)
end
BattleState[boundary]=R.finishWrapper
return true
end

function R.runWorkFrame(game,topBefore,topAfter,dt)
local stateChanged=topBefore~=topAfter
local perfNow=wallNow()
if R.activeBattle and StandaloneHost and StandaloneHost.updateCamera then StandaloneHost.updateCamera(dt) end
if R.activeBattle and not stateChanged and MoveFXExtractor and MoveFXExtractor.pumpPrefetch then
MoveFXExtractor.pumpPrefetch(1,2)
end




if not stateChanged and V.BattleCache and V.BattleCache.runtimeStatus
and V.BattleCache.pumpRuntimePreparation then
local held=V.BattleCache.runtimeStatus(game)
if held and held.owner==topAfter and held.waitingForModels and not held.error then
V.BattleCache.pumpRuntimePreparation(game,3)
return
end
end
if not R.activeBattle and not stateChanged then









local onOverworld=FrameWork and FrameWork.isOverworld(game,topAfter) or (topAfter and topAfter.isOverworld==true)






if onOverworld and not R.pendingEnd then
local post=V.MtBattlePostBattleFlow
if post and type(post.pump)=="function" then
local ok,pushed=pcall(post.pump,game,topAfter)
if not ok and type(game)=="table" then game.__cbeMtBattleIntermissionError=tostring(pushed) end
if ok and pushed==true then return end
end
end
local viewerWork=false
local hardCacheWork=false
if ResidentPrewarm then
if type(ResidentPrewarm.viewerActive)=="function" then
local ok,v=pcall(ResidentPrewarm.viewerActive);viewerWork=ok and v==true
end
if type(ResidentPrewarm.hardCacheRunning)=="function" then
local ok,v=pcall(ResidentPrewarm.hardCacheRunning);hardCacheWork=ok and v==true
end
end
if ResidentPrewarm and type(ResidentPrewarm.pump)=="function" then
if onOverworld or viewerWork or hardCacheWork then pcall(ResidentPrewarm.pump,game) end
elseif onOverworld and PokemonActors and type(PokemonActors.pumpPartyPrewarm)=="function" then


pcall(PokemonActors.pumpPartyPrewarm,game)
end



if onOverworld and MOBILE_RUNTIME and perfNow>=androidGcNextAt and PokemonActors and type(PokemonActors.gcStep)=="function" then
pcall(PokemonActors.gcStep,24);androidGcNextAt=perfNow+0.18
end
elseif R.activeBattle and not stateChanged and ResidentPrewarm
and ResidentPrewarm.viewerActive and ResidentPrewarm.viewerActive() then


pcall(ResidentPrewarm.pump,game,true)
elseif R.activeBattle and not stateChanged and PokemonActors
and type(PokemonActors.pumpBattlePrewarm)=="function" then
local presented=false
if StandaloneHost and type(StandaloneHost.status)=="function" then
local okStatus,status=pcall(StandaloneHost.status)
presented=okStatus and type(status)=="table" and status.presented==true and status.failOpen~=true
end



local doublesActive=false
if V.DoublesRuntime and type(V.DoublesRuntime.combat)=="function" then
local okD,session=pcall(V.DoublesRuntime.combat)
doublesActive=okD and session~=nil
end
local criticalBody=false
if type(PokemonActors.battlePrewarmStatus)=="function" then
local status=PokemonActors.battlePrewarmStatus()
criticalBody=(tonumber(status.criticalBodies) or 0)>0
end
if (presented or doublesActive) and (criticalBody or doublesActive or mobileSinglesPrewarmSafe(R.activeBattle)) then
local okPump,worked,pending=pcall(PokemonActors.pumpBattlePrewarm,3)
if okPump and (worked==true or (tonumber(pending) or 0)>0) then return end
end
if type(PokemonActors.pumpActionPrewarm)=="function" then
pcall(PokemonActors.pumpActionPrewarm,1,3)
end
elseif R.activeBattle and not stateChanged and perfNow>=androidActionWarmNextAt and PokemonActors and type(PokemonActors.pumpActionPrewarm)=="function" then



pcall(PokemonActors.pumpActionPrewarm,1);androidActionWarmNextAt=perfNow+0.07
end
end
function R.attachFrame(game)
return FrameWork and FrameWork.attach(game,R.runWorkFrame) or false
end






function R.closeWithoutResult(battle,reason)
battle=Compat and Compat.prepare(battle) or battle
local active=R.activeBattle
if not battle then battle=active end
if not battle then return false,"no active battle" end
if active and active~=battle and Compat and type(Compat.matches)=="function" then
local ok,matched=pcall(Compat.matches,active,battle)
if not (ok and matched==true) then return false,"battle is not active" end
elseif active and active~=battle then
return false,"battle is not active"
end
finishPresentation(battle,reason or "battle.suspended")
return true
end

function R.install()
if R.installed then installGen2FinishBoundary();installCaptureSoundBridge();return true end

installGen2FinishBoundary()
installCaptureSoundBridge()

if mod.hooks and type(mod.hooks.wrap)=="function" then
mod.hooks:wrap("input.step",function(next,game,dt)





local topBefore=stackTop(game)
local result=next(game,dt)
local topAfter=stackTop(game)
local stateChanged=topBefore~=topAfter







if R.pendingEnd and not (Compat and Compat.isGen2Battle(R.pendingEnd)) then
local stillBattle=false
if topAfter then
stillBattle=(topAfter==R.pendingEnd)
if not stillBattle and Compat and type(Compat.matches)=="function" then
local okMatch,matched=pcall(Compat.matches,R.pendingEnd,topAfter)
stillBattle=okMatch and matched==true
end
end
if not stillBattle then
finishPresentation(R.pendingEnd,R.pendingEndReason or "gen1.stack-exited")
end
end

if BattleDirector and R.activeBattle and type(BattleDirector.update)=="function" then
pcall(BattleDirector.update,BattleDirector,contextFor(R.activeBattle),dt)
end


if not (FrameWork and FrameWork.active(game)) then
R.attachFrame(game)
if not (FrameWork and FrameWork.attached(game)) then R.runWorkFrame(game,topBefore,topAfter) end
end
if StandaloneHost then




if R.activeBattle then pcall(StandaloneHost.install,true) end
StandaloneHost.update(dt)
end
return result
end)
end

if mod.events and type(mod.events.on)=="function" then
mod.events:on("battle.started",beginBattle)
for _,name in ipairs(SEMANTIC_EVENTS) do
mod.events:on(name,function(payload) dispatch(name,payload) end)
end
mod.events:on("battle.ended",endBattle)
end

R.attachFrame(mod.game)
R.installed=true
return true
end

function R.status()
return {installed=R.installed,active=R.activeBattle~=nil,pendingEnd=R.pendingEnd~=nil,
endBoundary=(Compat and Compat.current and Compat.current()==2) and "gen2.screen.finished" or "gen1.stack-exited",
exitPresentationLatch=R.pendingEnd~=nil and (R.pendingEndReason or "pending") or "idle",
captureSoundBridge=R.captureSoundBridge==true,nativeCaughtSuppressed=R.nativeCaughtSuppressed or 0,
moveSoundBridge=R.moveSoundBridge==true,nativeMoveSoundsSuppressed=R.nativeMoveSoundsSuppressed or 0,
modelPrewarm=R.modelPrewarm,entryTiming=R.entryTiming,exitTiming=R.exitTiming,
captureSuccessAudio="ISO me_snatch owns success; native Caught_Mon suppressed only when source cue is available",
moveAudio="Waza type-5 GameSound owns native battle-animation SFX only when the complete generated snd_se_battle WAV set is present"}
end

return R
