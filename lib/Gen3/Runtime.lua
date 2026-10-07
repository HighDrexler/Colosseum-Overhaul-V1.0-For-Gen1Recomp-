
local V=...
local req=V.engineRequire or require
local R={version=1,installed=false,facades=setmetatable({},{__mode='k'})}
local function pack(...) return {n=select('#',...),...} end
local unpack=table.unpack or unpack
function R.session(game)
if V.Gen3Challenge and V.Gen3Challenge.liveSession then return V.Gen3Challenge.liveSession end
local native=req('src.core.game3.runtime')
return (native.getSession and native.getSession()) or (game and game.session)
end
function R.data(game)
local s=R.session(game or V.mod.game)
if not s then return nil end
s.modData=s.modData or {}
local d=s.modData.COLOSSEUM_OVERHAUL
if type(d)~='table' then d={version=1};s.modData.COLOSSEUM_OVERHAUL=d end
d.prefs=d.prefs or {}
if game and game.save then game.save.colosseumBattle=d.prefs end
return d
end
function R.prefs(game)
game=game or V.mod.game
local d=R.data(game)
local GameVersion=req('src.core.GameVersion')
local version=GameVersion.get()
local hoenn=GameVersion.layout and GameVersion.layout(version)=='rse'
or version=='emerald' or version=='ruby' or version=='sapphire'
if d and hoenn and d.prefs.expandedWild==nil then
d.prefs.expandedWild=false
end
if d and hoenn then
local s=R.session(game)
local female=s and (s.gender==1 or s.gender=='female' or s.gender=='F')
if d.prefs.playerModel==nil then d.prefs.playerModel=female and 'may' or 'brendan' end
if d.prefs.rivalModel==nil then d.prefs.rivalModel=female and 'brendan' or 'may' end
end
return V.BattleSettings.prefs(game)
end



local function movesChanged(row)
local old=row.moveFxMoves
if not old then old={slots={}};row.moveFxMoves=old end
local changed=not old.initialized or old.mon~=row.mon
local moves=row.mon and row.mon.moves
local count=0
if moves then
for key,slot in pairs(moves) do
local identity=tostring(type(slot)=='table' and (slot.index or slot.moveId or slot.id or slot.name) or slot)
count=count+1
if old.slots[key]~=identity then old.slots[key]=identity;changed=true end
end
end
if old.count~=count then changed=true end
if changed then
for key in pairs(old.slots) do if not moves or moves[key]==nil then old.slots[key]=nil end end
old.mon=row.mon;old.count=count;old.initialized=true
end
return changed
end
function R.sync(f)
local st=f._model
f.game=R.game or V.mod.game
f.kind=st.wild and 'wild' or 'trainer';f.wild=st.wild;f.double=st.double==true
if type(st.trainer)=='table' then f.trainer=st.trainer
else
f.nativeTrainer=f.nativeTrainer or {}
local trainer=f.nativeTrainer
trainer.id=st.trainerId;trainer.name=st.trainerName or 'TRAINER';trainer.class=st.trainerClass
f.trainer=trainer
end
local version=req('src.core.GameVersion').get()
local constants=req('src.core.game3.constants').of(version)
local class=constants:name('trainer_classes',tonumber(st.trainerClass or f.trainer.class),'TRAINER_CLASS_')
f.trainerName=f.trainer.name;f.oppName=f.trainer.name;f.oppClass=class or st.trainerClassName or f.trainer.class


f.__cbeNativeRival=not st.wild and not st.link and (class=='TRAINER_CLASS_RIVAL'
or class=='TRAINER_CLASS_RIVAL_EARLY' or class=='TRAINER_CLASS_RIVAL_LATE'
or ((version=='firered' or version=='leafgreen') and class=='TRAINER_CLASS_CHAMPION'))
f.result=st.result;f.turnCount=st.turn;f.playerParty=st.playerParty;f.enemyParty=st.foeParty
f.cbeMtBattleChallenge=st.cbeMtBattleChallenge;f.cbeMtBattleNumber=st.cbeMtBattleNumber
local Anim=req('src.core.game3.battle.anim')
local P=req('src.core.game3.pokemon');local Ui=req('src.core.game3.battle.ui')
for id=0,3 do
local b=(st.battlers and st.battlers[id]) or (id==0 and st.player or id==1 and st.enemy)
local shown=b and Anim.shownBattler(id,b) or nil
local row=f.battlers[id] or {__cbeGen3Slot=true,battlerId=id,side=id%2==0 and 'player' or 'enemy',isPlayer=id%2==0}
f.battlers[id]=row
row.mon=shown and shown.mon or nil
row.native=shown
row.absent=(id>=2 and not st.double) or (st.absent and st.absent[id]) or not row.mon
local pres=Anim.present(id)
local appearance=pres and (pres.transformSpecies or shown and shown.species)
local substitute=pres and pres.substitute
local form=appearance and P.national(appearance)==351 and Ui.castformForm(id,shown) or 0
if R.active==f and (row.spriteMon~=(shown and shown.mon) or row.readySpecies~=appearance
or row.readySubstitute~=substitute or row.readyAbsent~=row.absent or row.readyCastformForm~=form) then R.readinessDirty=true end
row.readySpecies=appearance;row.readySubstitute=substitute
row.readyAbsent=row.absent;row.readyCastformForm=form
row.visible=not row.absent and (not pres or pres.visible~=false)
and not (pres and (pres.battlerInvisible or pres.invisible))
row.presentation=pres
row.fainted=row.mon and (row.mon.hp or 0)<=0 or false



if R.active==f and V.MoveFXExtractor and V.MoveFXExtractor.queueBattler then
if movesChanged(row) then
R.readinessDirty=true
local parts={tostring(row.mon)}
local moves={}
for key,identity in pairs(row.moveFxMoves.slots) do moves[#moves+1]=tostring(key).."="..identity end
table.sort(moves)
for _,value in ipairs(moves) do parts[#parts+1]=value end
local signature=table.concat(parts,":")
if row.moveFxMoveSignature~=signature then
row.moveFxMoveSignature=signature
if row.mon then V.MoveFXExtractor.queueBattler(f,row) end
end
end
end
if row.mon~=row.spriteMon then
local pic=row.mon and P.monFrontPic(row.mon)
row.sprite=pic and pic.image;row.spriteMon=row.mon
end
end
f.player=f.battlers[0];f.enemy=f.battlers[1]
f.sides.player.battler=f.player;f.sides.enemy.battler=f.enemy
return f
end
function R.prepare(st)
if st.__cbeGeneration==3 then return R.sync(st) end
if not (st.playerParty and st.player and st.enemy) then return st end
local f=R.facades[st]
if not f then
f={__cbePresentation=true,__cbeGeneration=3,_model=st,battlers={},sides={player={},enemy={}}}
function f:currentMapId() local s=R.session(self.game);return s and s.map end
function f:picImage(image) return image end
function f:actorHidden(b) return not b.visible end
function f:fxHidden(b) return not b.visible end
R.facades[st]=f
end
return R.sync(f)
end
function R.healthy(party)
local n=0
local P=req('src.core.game3.pokemon')
for _,m in ipairs(party or {}) do
if not P.isEgg(m) and (tonumber(m.hp) or 0)>0 then n=n+1 end
end
return n
end
function R.queueMoveFX(f)
local E=V.MoveFXExtractor
if not (E and E.queueBattle and f) then return 0 end
E.queueBattle(f)
if E.queueBattler then
for _,party in ipairs({f.playerParty or {},f.enemyParty or {}}) do
for _,mon in ipairs(party) do E.queueBattler(f,{mon=mon}) end
end
end
local status=E.status and E.status() or nil
return tonumber(status and status.pending) or 0
end
function R.pumpMoveFX(maxItems,criticalOnly)
local E=V.MoveFXExtractor
if not (E and E.pumpPrefetch) then return nil end
local out=E.pumpPrefetch(maxItems or 1,2,criticalOnly)
R.moveFxFailed=(R.moveFxFailed or 0)+(tonumber(out and out.failed) or 0)
for _,failure in ipairs(out and out.failedJobs or {}) do
R.moveFxError=tostring(failure.stem)..": "..tostring(failure.reason)
if V.FxDiagnostics then pcall(V.FxDiagnostics.note,'move.prefetch_failed',failure) end
end
return out
end
function R.promote(opts,enabled)

if not enabled or opts.double or opts.wild or opts.link or opts.multi or opts.spectate
or opts.safari or opts.oldManTutorial or opts.pokedude or opts.firstBattle
or opts.earlyRival or opts.ghostBattle or opts.ghostUnveiled or opts.trainerTower
or opts.battleTower or opts.eReader or opts.cbeKeepFormat then return opts end
local foe=opts.foe or {}
if foe.link or foe.safari or foe.oldManTutorial or foe.firstBattle or foe.ghostBattle then return opts end
local party=opts.foeParty or foe.party
if R.healthy(opts.playerParty)<2 or not party or #party<2 then return opts end

local count=0
for _,m in ipairs(party) do if not m.isEgg and not m.egg and (m.hp==nil or m.hp>0) then count=count+1 end end
if count<2 then return opts end
local out={};for k,v in pairs(opts) do out[k]=v end
out.double=true
return out
end
function R.finish(reason)
local f=R.active
if V.Gen3Capture then V.Gen3Capture.reset() end
V.StandaloneHost.finish(reason or 'native Gen 3 battle ended')
V.Gen3Presentation.finish()
V.PokemonActors.cancelBattlePrewarm(reason)


if f and f._model then R.facades[f._model]=nil end
R.active=nil
R.waitingForModels=false;R.modelError=nil;R.nativeModelFallback=nil;R.holdSeconds=0
R.pendingMoveFX=0;R.moveFxFailed=0;R.moveFxError=nil
if V.Gen3Screens and V.Gen3Screens.releaseBattleBackdrop then V.Gen3Screens.releaseBattleBackdrop() end
end
function R.begin(st,opts)
R.finish('replaced')
R.readinessKnown=nil;R.readinessDirty=true
if opts and opts.cbeMtBattleNumber then
st.cbeMtBattleNumber=opts.cbeMtBattleNumber;st.cbeMtBattleChallenge=true
end
local f=R.prepare(st);R.active=f
if V.Gen3Screens and V.Gen3Screens.captureBattleBackdrop then V.Gen3Screens.captureBattleBackdrop() end
if V.Gen3Screens and V.Gen3Screens.cancelPrefetch then V.Gen3Screens.cancelPrefetch() end
if V.ResidentPrewarm and V.ResidentPrewarm.cancelViewer then V.ResidentPrewarm.cancelViewer() end
if V.PokemonActors.suspendHardCache then V.PokemonActors.suspendHardCache() end
V.PokemonActors.cancelPartyPrewarm()
if V.MoveFXExtractor and V.MoveFXExtractor.suspendPrefetch then V.MoveFXExtractor.suspendPrefetch() end
V.ArenaCatalog.sync(f.game)
V.StandaloneHost.begin(f)
V.PokemonActors.prewarmBattle(f,{deferCold=true})
for id=0,3 do local b=f.battlers[id]
if b and not b.absent then V.PokemonActors.queueBattlePrewarm(f,tostring(id),b,true) end
end




R.queueMoveFX(f)
R.refreshReadiness(0)
end
local function pendingActiveMoveFX(f)
local E=V.MoveFXExtractor
local pending=0
if E and E.battlerReady then for _,row in pairs(f and f.battlers or {}) do
if not row.absent and not E.battlerReady(f,row) then E.queueBattler(f,row,true);pending=pending+1 end
if not row.absent and E.faintReturnReady and V.ReleasePresentation and V.ReleasePresentation.ballStem then
local stem=V.ReleasePresentation.ballStem(row.mon)
if not E.faintReturnReady(stem) then E.queueFaintReturn(stem);pending=pending+1 end
end
end elseif E and E.status then pending=tonumber(E.status().pending) or 0 end
return pending
end
function R.refreshReadiness(dt,force)
local f=R.active;local B=req('src.core.game3.battle');local st=f and f._model
local stage=V.StandaloneHost.session
local p=R.prefs()
local required=st and not B._headless and not st.link and not R.nativeModelFallback
and p.pokemonModelsEnabled and p.arenasEnabled and V.PokemonActors.peek
and not (st.safari or st.pokedude or st.oldManTutorial or st.ghostBattle)
if not required or not (stage and stage.context) then
R.waitingForModels=false;return true
end



R.sync(f)
if not force and R.readinessKnown and not R.waitingForModels and not R.readinessDirty then return true end


if R.waitingForModels and (tonumber(dt) or 0)>0 then
V.Gen3Presentation.update(stage.context,dt)
elseif V.Gen3Presentation.refresh then V.Gen3Presentation.refresh(stage.context)
else V.Gen3Presentation.update(stage.context,0) end


R.pendingMoveFX=pendingActiveMoveFX(f)
local ready,missing,err=V.Gen3Presentation.readiness()
local native=req('src.core.game3.battle.anim')
local nativePending=V.WorkBudget and native.loadPack and not R.nativeAnimationError
and not (native._packLoaded and native._pack) and 1 or 0
R.waitingForModels=not ready or R.pendingMoveFX>0 or nativePending>0
R.missingModels=(tonumber(missing) or 0)+R.pendingMoveFX+nativePending;R.modelError=err
R.readinessKnown=true;R.readinessDirty=false
if not R.waitingForModels then R.holdSeconds=0 else R.holdSeconds=(R.holdSeconds or 0)+(dt or 0) end
return not R.waitingForModels
end
function R.warmSession(game)
local session=R.session(game)
if session and session~=R.warmedSession and V.ResidentPrewarm then


if not V.ResidentPrewarm.hardCacheRunning() then V.ResidentPrewarm.queueStartup(game) end
R.warmedSession=session
end
end
function R.prepareCache()
R.warmSession(R.game or V.mod.game)
if V.Gen3Screens and V.Gen3Screens.cancelPrefetch then V.Gen3Screens.cancelPrefetch() end
if V.ResidentPrewarm and V.ResidentPrewarm.cancelViewer then V.ResidentPrewarm.cancelViewer() end
end



function R.pumpNativeAnimations()
local A=req('src.core.game3.battle.anim')
local W=V.WorkBudget
if A._packLoaded and A._pack then
if R.nativeAnimationTask and W then W.cancel(R.nativeAnimationTask) end
R.nativeAnimationTask=nil;return true
end
if not W or not A.loadPack or R.nativeAnimationError then return true end
if not R.nativeAnimationTask then
R.nativeAnimationTask=W.new(function()
local cache=req('src.core.game3.dataset').cache()
local root='data/generated/gba/pokemon/battle_anims/'
local src=assert(cache:read(root..'pack.lua'),'native animation pack unavailable')
local pack=assert((loadstring or load)(src,'@'..root..'pack.lua'))()
assert(type(pack)=='table' and type(pack.tags)=='table','native animation pack invalid')
local images={}
local commit=W.onCancel(function()for _,img in ipairs(images)do pcall(img.release,img)end end)
local Pal=req('src.core.game3.battle.anim_pal')
for tag,info in pairs(pack.tags)do
W.checkpoint('Preparing native fallback effect '..tostring(tag))
if type(info)=='table' and not info.image and info.file then
local bytes=cache:read(root..info.file)
if type(bytes)=='string' and #bytes>0 then
local data=love.filesystem.newFileData(bytes,info.file)
local pixels=love.image.newImageData(data)
pixels:mapPixel(function(_,_,r,g,b,a)
if a<.01 or (math.abs(r-98/255)<.004 and math.abs(g-41/255)<.004 and math.abs(b-1)<.004)
or (b>.95 and r>.30 and r<.50 and g<.25) then return 0,0,0,0 end
return r,g,b,a
end)
local image=love.graphics.newImage(pixels);images[#images+1]=image
image:setFilter('nearest','nearest');info.image=image;info.w=image:getWidth();info.h=image:getHeight()
pixels:release();data:release()
Pal.hydrateIndex(info,tag,image,function(path)return cache:read(root..path)end)
end
end
end
A.loadPack(pack);commit();return true
end,'Preparing native fallback effects')
end
local ok,state,result=W.resume(R.nativeAnimationTask,2)
if ok and state~='done' then return false end
R.nativeAnimationTask=nil
if not ok or not result then
R.nativeAnimationError=tostring(state)
if V.mod.log then V.mod.log:warn('Native effect preparation: %s',R.nativeAnimationError) end
end
return true
end
function R.attach(game)
R.game=game or R.game or V.mod.game
if not R.game then return end
if V.BattleTempo then V.BattleTempo.attach(R.game) end
R.data(R.game)
if not R.game.__cbeGen3Wheel then
local inner=R.game.wheelmoved
if V.FreeLookCamera or V.Gen3ModelCamera then
R.game.wheelmoved=function(g,x,y,...)
if V.Gen3ModelCamera and V.Gen3ModelCamera.wheel(x,y) then return true end
if V.FreeLookCamera and V.FreeLookCamera.wheel(g,x,y) then return true end
if inner then return inner(g,x,y,...) end
end
R.game.__cbeGen3Wheel=true
end
end
V.FrameWork.attach(R.game,function(g,_,_,dt)
R.data(g)
if R.active then
R.refreshReadiness(0,true)



if R.waitingForModels then
V.PokemonActors.pumpBattlePrewarm(3,true)
if R.pumpNativeAnimations() then
R.pumpMoveFX(1,true)
end
R.refreshReadiness(0,true)
end



local stage=V.StandaloneHost.session
local services=stage and stage.context.services
if services then services.presentationFrameClock=true end
V.StandaloneHost.update(math.max(0,math.min(.1,tonumber(dt) or 0)))
V.StandaloneHost.updateCamera(dt)
if services then services.presentationFrameClock=nil end
if not R.waitingForModels and V.Gen3UI and V.Gen3UI.viewer then V.Gen3UI.pump(dt) end
else
if V.Gen3MtBattleHub then V.Gen3MtBattleHub.pump(dt) end
R.warmSession(g)
if V.Gen3UI then V.Gen3UI.pump(dt) end
if not (V.Gen3UI and V.Gen3UI.viewer and not V.Gen3UI.viewer.nativeForm) then
local Stack=req('src.ui.game3.stack')
local safe=Stack.depth and Stack.depth()==0
if safe and V.FxDiagnostics then V.FxDiagnostics.flush() end
local warm=V.ResidentPrewarm
if safe then R.pumpNativeAnimations() end
if warm and (safe or warm.hardCacheRunning() or warm.viewerActive()) then warm.pump(g,not safe and warm.viewerActive())
elseif not warm and safe then V.PokemonActors.pumpPartyPrewarm(g) end
end
end
end)
end
function R.install()
R.attach(V.mod.game)
if V.ExpShare then V.ExpShare.installGen3() end
if R.installed then return true end
local B=req('src.core.game3.battle')
local U=req('src.core.game3.battle.ui')
local start,update,reset,abort=B.start,B.update,B.reset,B.abort
B.start=function(opts)
opts=R.promote(opts or {},R.prefs().doubleBattlesEnabled)
local result=pack(V.Gen3Challenge.scoped(start,opts))
if result[1] and B.isActive() then R.begin(B.getState(),opts) end
return unpack(result,1,result.n)
end
B.update=function(dt,game)
if game and R.game~=game then R.attach(game) end
if R.active and not R.refreshReadiness(0) then
local input=game and game.input
if R.modelError and input and input.wasPressed then
if input:wasPressed('a') then
V.PokemonActors.cancelBattlePrewarm('retry');R.modelError=nil
V.PokemonActors.prewarmBattle(R.active,{deferCold=true})
elseif input:wasPressed('b') then R.nativeModelFallback=true;R.waitingForModels=false end
end
if not V.FrameWork.attached(game or R.game) then
V.PokemonActors.pumpBattlePrewarm(6)
if R.pumpNativeAnimations() then R.pumpMoveFX(1) end
R.refreshReadiness(dt)
end
if R.waitingForModels then return end
end
local result=pack(V.Gen3Challenge.scoped(update,dt,game))
if B.isActive() then
if not R.active or R.active._model~=B.getState() then R.begin(B.getState()) end
R.sync(R.active)
local stage=V.StandaloneHost.session
R.syncCameraPhase(stage,B._phase)
if not V.FrameWork.active(game or R.game) then V.StandaloneHost.update(dt) end
R.refreshReadiness(0)
if not V.FrameWork.attached(game or R.game) then V.PokemonActors.pumpBattlePrewarm(3) end
elseif R.active then R.finish() end
return unpack(result,1,result.n)
end
B.reset=function(...) R.finish('reset');local out=pack(V.Gen3Challenge.scoped(reset,...));V.Gen3Challenge.release();return unpack(out,1,out.n) end
B.abort=function(...) local result=pack(V.Gen3Challenge.scoped(abort,...));R.finish('abort');V.Gen3Challenge.release();return unpack(result,1,result.n) end
local draw=U.draw


local stats=req('src.ui.game3.stat_growth')
U.draw=function(w,h)
if not R.active or not V.Gen3UI.drawBattle(R.active,U,w,h) then return draw(w,h) end


if stats and stats.isOpen() and B.statWindowPhase() then stats.draw() end
end
V.Gen3Presentation.install()
if V.Gen3Capture then V.Gen3Capture.install() end
V.Gen3UI.install()
if V.Gen3MoveMemory then V.Gen3MoveMemory.install() end
V.Gen3Challenge.install()
if V.Gen3LeagueScientist then V.Gen3LeagueScientist.install() end
if V.Gen3Audio then V.Gen3Audio.install() end
if V.mod.events and V.mod.events.on then
V.mod.events:on('game.ready',function(e) R.attach(e and e.game) end)
end
R.installed=true
return true
end
function R.syncCameraPhase(stage,phase)
if not stage then return end
local commands=phase=='command' and not V.Gen3Presentation.pendingMove
and not V.Gen3Presentation.faintActive()
if commands then
stage.context.phase='command'
if not stage.commandCamera then
stage.commandCamera=true;stage.context.progress=0
if V.Camera then V.Camera:event(stage.context,'battle.presentation_command',{}) end
end
else stage.commandCamera=false end
end
function R.status()
return {generation=3,installed=R.installed,combat='native-gen3',double=R.active and R.active.double or false,
presentation=V.Gen3Presentation.status(),challenge=V.Gen3Challenge.status(),
waitingForModels=R.waitingForModels,missingModels=R.missingModels,modelError=R.modelError,
pendingMoveFX=R.pendingMoveFX,moveFxFailed=R.moveFxFailed,moveFxError=R.moveFxError,
workError=R.game and R.game.__cbeAssetUpdateError}
end
return R
