








local V=...
local MoveFX=V.MoveFXExtractor
local MoveFXVM=V.MoveFXVM
local SourceTravel=V.MoveFXSourceTravel
local WazaSequence=V.WazaSequenceRuntime
local Director=V.BattleDirector
local GeneratedAssets=V.GeneratedAssets
local PlayerTrainer=V.PlayerTrainer
local P={
id=nil, registered=false, preferredPatched=false,
drawn={player=false,enemy=false}, presented={player=false,enemy=false},
battleArt=nil, animated=nil,
stadiumHandle=nil,stadiumApi=nil,stadiumActors={},retiringActors={},faintReturns={},stadiumError=nil,
stadiumRetry={},mobileRuntime=love and love.system and love.system.getOS
and (love.system.getOS()=="Android" or love.system.getOS()=="iOS") or false,
actorApi=nil,actorOwner=nil,
spriteApi=nil,spriteOwner=nil,spriteError=nil,
mode="sprites",modeId="builtin:resolved-sprites",externalProvider=nil,
externalBegun=false,externalError=nil,presentationFallback=nil,
moveFxActive={},moveFxImages={},moveFxShader=nil,moveFxError=nil,
}
local OWNER=(V.mod and V.mod.id) or "COLOSSEUM_BATTLE_ENVIRONMENTS"
local ModLookup=V.ModLookup
local registeredCapabilities={battleActors={},battleSprites={},battlePresentation={}}
local seenEventPayload=setmetatable({},{__mode="k"})
local BATTLE_ART_IDS={"BATTLE_ART_VOXEL_GEN2","BATTLE_ART_VOXEL_FORK","DRAMATIC_SHAPE"}
local STADIUM_ID="STADIUM_BATTLE_FX"
local STADIUM2_ID="STADIUM2_OVERWORLD_MODELS"
if ModLookup and type(ModLookup.remember)=="function" then
ModLookup.remember(STADIUM2_ID)
end

local function releaseActorRecord(record,reason)
if not record then return false end
local actor=record.actor
if actor and type(actor.remove)=="function" then
pcall(actor.remove,actor,reason or "removed")
end
if actor and type(actor.release)=="function" then pcall(actor.release,actor) end
return true
end

local function releaseStadiumActor(side,reason)
local record=P.stadiumActors[side]
if not record then return false end
local sourceReturn=P.faintReturns and P.faintReturns[side]
local RP=V and V.ReleasePresentation
if sourceReturn and RP and type(RP.finishFaint)=="function" then
pcall(RP.finishFaint,sourceReturn,nil,nil,reason or "actor-release")
elseif record.actor then
record.actor.cbeSourceFaintReturn=nil
end
P.stadiumActors[side]=nil
P.faintReturns[side]=nil
return releaseActorRecord(record,reason)
end






local function retireStadiumActor(side,reason)
local record=P.stadiumActors[side]
if not record then return false end
local sourceReturn=P.faintReturns and P.faintReturns[side]
local RP=V and V.ReleasePresentation
if sourceReturn and RP and type(RP.faintComplete)=="function" then
local okReturn,done=pcall(RP.faintComplete,sourceReturn)
if not okReturn or done~=true then return false end
if type(RP.finishFaint)=="function" then pcall(RP.finishFaint,sourceReturn,sourceReturn.context,nil,reason or "actor-retire") end
P.faintReturns[side]=nil



P.stadiumActors[side]=nil
return releaseActorRecord(record,"faint-complete")
elseif record.actor then
record.actor.cbeSourceFaintReturn=nil
end
P.stadiumActors[side]=nil
record.side=side
record.retireReason=reason or "replacement"
local actor=record.actor
local alreadyTerminal=actor and (actor.state=="faint" or actor.state=="recall")
if actor and not alreadyTerminal and type(actor.recall)=="function" then
pcall(actor.recall,actor,record.retireReason)
elseif actor and not alreadyTerminal and type(actor.remove)=="function" then
pcall(actor.remove,actor,record.retireReason)
end
P.retiringActors[#P.retiringActors+1]=record
return true
end

local function releaseRetiringActors(reason)
for i=#P.retiringActors,1,-1 do
local record=P.retiringActors[i]
table.remove(P.retiringActors,i)
releaseActorRecord(record,reason or record.retireReason or "removed")
end
end

local function releaseStadiumActors(reason)
P.stadiumRetry={}
local sides={}
for side in pairs(P.stadiumActors) do sides[#sides+1]=side end
for _,side in ipairs(sides) do releaseStadiumActor(side,reason) end
releaseRetiringActors(reason)
end







local function stadiumService()
local handle=ModLookup.find(V.mod,STADIUM_ID)
local api=handle and handle.exports and handle.exports.models
if not (type(api)=="table" and tonumber(api.version)==1
and type(api.acquire)=="function" and type(api.withRenderer)=="function") then
if P.stadiumHandle~=handle or P.stadiumApi~=nil then releaseStadiumActors("provider-unavailable") end
P.stadiumHandle=handle;P.stadiumApi=nil
return nil
end
if P.stadiumHandle~=handle or P.stadiumApi~=api then
releaseStadiumActors("provider-changed");P.stadiumHandle=handle;P.stadiumApi=api
end
return api
end

local function standaloneContext(context)
return context and context.services and context.services.cbeStandalone==true
end

local function validActorApi(api)
return type(api)=="table" and tonumber(api.version)==1
and type(api.acquire)=="function" and type(api.withRenderer)=="function"
end

local function selected(api,context)
if type(api.selected)~="function" then return true end
local ok,value=pcall(api.selected,context)
return ok and value~=false
end

local function bestCapability(context,keys,valid)
local game=(context and context.game) or (context and context.battle and context.battle.game)
local best,bestHandle,bestScore
local function consider(api,handle)
if valid(api) and selected(api,context) then
local score=tonumber(api.priority) or 0
if not best or score>bestScore
or (score==bestScore and tostring(handle.id)<tostring(bestHandle.id)) then
best,bestHandle,bestScore=api,handle,score
end
end
end
local handles=ModLookup.each and ModLookup.each(V.mod,game) or {}
for _,handle in ipairs(handles) do
if handle and handle.id~=OWNER then
local exports=handle.exports
local api
for _,key in ipairs(keys) do
if exports and exports[key]~=nil then api=exports[key];break end
end
consider(api,handle)
end
end



for _,key in ipairs(keys) do
local bucket=registeredCapabilities[key]
if bucket then
for owner,api in pairs(bucket) do consider(api,{id=owner,exports={}}) end
end
end
return best,bestHandle
end

local function validPresentationApi(api)
return type(api)=="table" and tonumber(api.version)==1
and api.portable~=false and type(api.drawWorld)=="function"
and type(api.covers)=="function"
end

local function portablePresentationService(context)
return bestCapability(context,{"battlePresentation","battlePresenter"},validPresentationApi)
end

local function validSpriteApi(api)
return type(api)=="table" and tonumber(api.version)==1
and type(api.resolve)=="function"
end





local function portableSpriteService(context)
return bestCapability(context,{"battleSprites","battleSpriteProvider"},validSpriteApi)
end





local function portableActorService(context)
local api,handle=bestCapability(context,{"battleActors"},validActorApi)
if api then return api,handle end


return bestCapability(context,{"models"},function(value)
return type(value)=="table" and value.portable==true and validActorApi(value)
end)
end

local function cbePokemonModelsEnabled(context)
local settings=V.BattleSettings
if not (settings and type(settings.pokemonModelsEnabled)=="function") then return true end
local game=(context and context.game) or (context and context.battle and context.battle.game) or (V.mod and V.mod.game)
local ok,value=pcall(settings.pokemonModelsEnabled,game)
return (not ok) or value~=false
end

local function cbePokemonActorService(context)
if not cbePokemonModelsEnabled(context) then return nil end
local actors=V.PokemonActors
local api=actors and actors.service
if validActorApi(api) and selected(api,context) then return api end
return nil
end

local function desiredPresentation(context)
P.presentationFallback=nil





local cbeApi=cbePokemonActorService(context)
if cbeApi then
return "stadium","cbe:colosseum-pokemon",cbeApi,{id=OWNER.."/pokemon",exports={}}
end









local stageOwned=true
local C=V.ArenaCatalog
if C and type(C.enabled)=="function" then
local game=(context and context.game) or (context and context.battle and context.battle.game) or (V.mod and V.mod.game)
local ok,value=pcall(C.enabled,game)
if ok then stageOwned=value~=false end
end
if not stageOwned then
local presenter,presenterHandle=portablePresentationService(context)
if presenter then
return "external",tostring(presenterHandle.id)..":battle-presentation",presenter,presenterHandle
end
end
local portable,portableHandle=portableActorService(context)
if portable then
return "stadium",tostring(portableHandle.id)..":battle-actors",portable,portableHandle
end



if not standaloneContext(context) then
return "sprites","builtin:resolved-sprites",nil
end
local handle=ModLookup.find(V.mod,STADIUM_ID)
local exports=handle and handle.exports
local actors=stadiumService()
local registry=exports and exports.battles
if not (type(registry)=="table" and tonumber(registry.version)==1
and type(registry.selectedId)=="function" and type(registry.resolve)=="function") then


if actors then return "stadium","stadium:legacy-selected",actors,handle end
return "sprites","builtin:resolved-sprites",nil
end
local okSelected,selected=pcall(registry.selectedId,registry,"models")
if not okSelected then return "sprites","builtin:resolved-sprites",nil end
selected=tostring(selected or "stadium:default")
if selected=="off" then return "native","off",nil end
local okResolve,provider,entry=pcall(registry.resolve,registry,"models",context)
if not okResolve then
P.externalError=tostring(provider)
return "sprites","builtin:resolved-sprites",nil
end
local resolvedId=(type(entry)=="table" and entry.id) or selected
P.presentationFallback=registry.FALLBACK
if provider==P or (P.id and resolvedId==P.id) then
return "sprites",resolvedId,provider
end
local builtin=exports and exports.modelProvider
if provider==builtin or resolvedId=="stadium:default" then
if actors then return "stadium",resolvedId,actors,handle end
return "sprites","builtin:resolved-sprites",nil
end




if validActorApi(provider) then
return "stadium",resolvedId,provider,handle
end
return "sprites","builtin:resolved-sprites",nil
end

local function invokeExternal(context,method,...)
local provider=P.externalProvider
local fn=provider and provider[method]
if type(fn)~="function" then return true,nil end
local ok,a,b,c=pcall(fn,provider,context,...)
if not ok then P.externalError=tostring(a);return false,a end
return true,a,b,c
end

local function finishExternal(context,reason)
if P.externalProvider and P.externalBegun then
invokeExternal(context,"finish",reason or "selection-changed")
end
P.externalProvider=nil;P.externalBegun=false
end

local function selectPresentation(context,force)
local mode,id,provider,handle=desiredPresentation(context)
if not force and mode==P.mode and id==P.modeId
and (mode~="external" or provider==P.externalProvider)
and (mode~="stadium" or provider==P.actorApi) then return mode end
finishExternal(context,"selection-changed")
releaseStadiumActors("presentation-changed")
P.mode=mode;P.modeId=id;P.externalError=nil
P.actorApi=(mode=="stadium") and provider or nil
P.actorOwner=(mode=="stadium" and handle and handle.id) or nil
if mode=="external" then
P.externalProvider=provider
local ok,accepted=invokeExternal(context,"begin",context and context.arena)
if not ok or accepted==false or accepted==P.presentationFallback then
finishExternal(context,"begin-declined")
P.mode="sprites";P.modeId="builtin:resolved-sprites"
else
P.externalBegun=true
end
end
return P.mode
end

local function arenasEnabled(context)
local C=V.ArenaCatalog
if not (C and type(C.enabled)=="function") then return true end
local battle=context and context.battle
local game=(context and context.game) or (battle and battle.game) or (V.mod and V.mod.game)
local ok,value=pcall(C.enabled,game)
return not ok or value~=false
end

local function ourArena(context)
local arena=context and context.arena
local id=arena and tostring(arena.id or "") or ""
return id:find("^COLOSSEUM_BATTLE_ENVIRONMENTS:")~=nil
end








local function cbeFxWorldActive(context)
if ourArena(context) then return true end
local host=V and V.StandaloneHost
if host and type(host.status)=="function" then
local ok,st=pcall(host.status)
if ok and type(st)=="table" and st.active==true then return true end
end
local bridge=V and V.StadiumBridge
local battle=context and context.battle
if bridge and type(bridge.ownsArena)=="function" then
local ok,owned=pcall(bridge.ownsArena,battle)
if ok and owned==true then return true end
end
return false
end










function P.informationActorProvider(request)
request=type(request)=="table" and request or {}
local game=request.game or (V.mod and V.mod.game)
local mon=request.mon or request.pokemon
local battler=request.battler
if type(battler)~="table" and type(mon)=="table" then battler={mon=mon} end
local context={
apiVersion=1,
game=game,
battle=nil,
sides={player={battler=battler},enemy={battler=nil}},
phase="information",progress=1,groundY=0,
services={cbeStandalone=true,informationSurface=true,informationAnimation=true},
}
local mode,id,provider,handle=desiredPresentation(context)
if mode~="stadium" or not validActorApi(provider) then
return nil,tostring(mode or "sprites"),context
end
return provider,tostring(id or "portable-actors"),context,
handle and handle.id or nil
end

local function battleArtHandle()
for _,id in ipairs(BATTLE_ART_IDS) do
local h=ModLookup.find(V.mod,id); if h then return h,id end
end
return nil
end

local function battleArtRuntime()
local h,id=battleArtHandle()
if not h then P.battleArt=nil;P.animated=nil;return nil end
if P.battleArt and P.battleArt.handle==h then return P.battleArt end
local lib=h.exports and h.exports.lib
if not (type(lib)=="table" and type(lib.require)=="function") then return nil end
local art,animated
pcall(function() art=lib.require("BattleArt") end)
pcall(function() animated=lib.require("AnimatedBattleArt") end)
P.battleArt={handle=h,id=id,art=art}
P.animated=animated
return P.battleArt
end

local function battleArtWantsWorldSprites()




return battleArtRuntime() ~= nil
end












local function syncBattleArtSpecies(context,dt,advance)
if not (context and context.battle) then return false end
if cbePokemonModelsEnabled(context) then P.spriteOwner=nil;return false end
local runtime=battleArtRuntime()
local art=runtime and runtime.art
if not art then return false end
local battle=context.battle
local animated=P.animated





if advance and animated and type(animated.update)=="function" then
pcall(animated.update,battle,math.max(0,tonumber(dt) or 0))
end





if type(art.apply)=="function" then pcall(art.apply,battle) end

if animated and type(animated.reassert)=="function" then
if battle.enemy then pcall(animated.reassert,battle.enemy) end
if battle.player then pcall(animated.reassert,battle.player) end
end
local owns=true
if type(art.ownsSpeciesArt)=="function" then
local ok,value=pcall(art.ownsSpeciesArt)
owns=ok and value~=false
end
P.spriteOwner=owns and runtime.id or nil
return owns
end

local function liveBattler(context,side)
local battle=context and context.battle




local b=battle and battle[side]
if not b then
local entry=context and context.sides and context.sides[side]
b=entry and entry.battler or nil
end
if context and context.sides then
context.sides[side]=context.sides[side] or {}
context.sides[side].battler=b
end
return b
end

local function dexFor(context,battler)
if V.ModelIdentity then return V.ModelIdentity.resolve(context and (context.game or (context.battle and context.battle.game)),battler) end
local mon=battler and battler.mon
local species=mon and mon.species
local game=(context and context.game) or (context and context.battle and context.battle.game)
local def=game and game.data and game.data.pokemon and game.data.pokemon[species]


local dex=(def and (def.dex or def.index or def.number))
or (mon and (mon.dex or mon.speciesIndex))
return tonumber(dex),(V.ShinySupport and V.ShinySupport.variant(battler)) or (mon and mon.shiny and "shiny" or "normal")
end






local STRUCTURAL_HIDE_MOVE={[19]=true,[91]=true,fly=true,dig=true}
local function actorStructuralHide(actor)
if not actor then return false end
local move=actor.lastMove
local key=tonumber(move) or tostring(move or ""):lower():gsub("[^a-z0-9]","")
return STRUCTURAL_HIDE_MOVE[key]==true
end

local function doublesOpeningPending(context)
local runtime=V and V.DoublesRuntime
if not (runtime and type(runtime.openingPending)=="function") then return false end
local ok,pending=pcall(runtime.openingPending,context and context.battle)
return ok and pending==true
end

local function actorAcquirePending(err)
local msg=tostring(err or "")
return msg:find("variant not resident",1,true)~=nil
or msg:find("pending cooperative preparation",1,true)~=nil
or msg:find("pending storage-action upgrade",1,true)~=nil
or msg:find("storage-only model needs battle action upgrade",1,true)~=nil
or msg:find("source extraction in progress",1,true)~=nil
end

local function stadiumActor(context,side)
if P.mode~="stadium" then return nil end
local api=P.actorApi or stadiumService()
if not api then return nil end
local battler=liveBattler(context,side)
local compat=V.GenerationCompat
if compat and type(compat.isEmptyBattler)=="function" and compat.isEmptyBattler(battler) then return nil end
local dex,variant=dexFor(context,battler)
local record=P.stadiumActors[side]
if not dex or dex<1 then
P.stadiumError="no National Dex mapping for "..tostring(battler and battler.mon and battler.mon.species)
releaseStadiumActor(side,"missing-dex")
if P.modeId=="cbe:colosseum-pokemon" and V.BattleCache then V.BattleCache.noteRenderError(context.game,P.stadiumError) end
return nil
end
local key=tostring(dex)..":"..variant
if record and record.key==key then





record.battler=battler
return record.actor
end
if record then retireStadiumActor(side,"replacement") end
local source=api.SELECTED or "selected"
local cbe=P.modeId=="cbe:colosseum-pokemon"
local streaming=cbe and api.cooperativePreparation==true


if not cbe and type(api.available)=="function" then
local ok,available=pcall(api.available,source,dex)
if not (ok and available) then
P.stadiumError=ok and ("actor provider reports model "..tostring(dex).." unavailable") or tostring(available)
return nil
end
end
local now=(love and love.timer and love.timer.getTime and love.timer.getTime()) or os.clock()
local retry=P.stadiumRetry[side]
if cbe and retry and retry.key==key and retry.battle==context.battle and now<retry.at then return nil end
local opts={side=side,context=context,battler=battler,
allowStorageBattleBody=cbe and (P.mobileRuntime or streaming),allowLegacyMaterialBody=cbe,
noSource=cbe and (P.mobileRuntime or streaming) or false}
local ok,actor,err
if cbe and type(api.acquireCached)=="function" then
ok,actor,err=pcall(api.acquireCached,source,dex,variant,opts)
end
if (not ok or not actor) and not streaming then
opts.noSource=cbe and P.mobileRuntime or false
ok,actor,err=pcall(api.acquire,source,dex,variant,opts)
end



if cbe and (P.mobileRuntime or streaming) and V.PokemonActors and type(V.PokemonActors.queueBattlePrewarm)=="function" then
local owner=context and context.battle
if not (owner and owner.game) then owner={game=context and context.game} end
pcall(V.PokemonActors.queueBattlePrewarm,owner,side,battler,true)
end
if not ok or not actor then
local reason=tostring(ok and err or actor)
local pending=ok and actorAcquirePending(err)
if cbe then P.stadiumRetry[side]={key=key,battle=context.battle,at=now+.05} end
P.stadiumError=(not pending) and reason or nil
P.stadiumPending=pending and reason or nil
if not pending and P.modeId=="cbe:colosseum-pokemon" and V.BattleCache then
V.BattleCache.noteRenderError(context.game,P.stadiumError)
end
return nil
end
P.stadiumError=nil;P.stadiumPending=nil;P.stadiumRetry[side]=nil
P.stadiumActors[side]={key=key,actor=actor,dex=dex,variant=variant,
battler=battler,state="spawn"}
return actor
end

local growScale
local function visible(context,side)
local battle=context and context.battle
local b=liveBattler(context,side)
if not (battle and b and b.sprite) then return false end
if doublesOpeningPending(context) then return false end
if side=="enemy" then
if PlayerTrainer and type(PlayerTrainer.captureHidesEnemy)=="function" then
local okHide,hide=pcall(PlayerTrainer.captureHidesEnemy,PlayerTrainer,context)
if okHide and hide then return false end
end
if battle.showEnemyTrainer or battle.enemyHidden then return false end
if battle.enemySendingOut then



local scale=growScale(context,b)
if not (scale and scale>0) then return false end
end
else
if battle.showPlayerBack or battle.safari or battle.demo then return false end
if battle.sendingOut then
local scale=growScale(context,b)
if not (scale and scale>0) then return false end
end
end





local faintActive=false
if type(battle.fxFaintActive)=="function" then
local ok,value=pcall(battle.fxFaintActive,battle,b)
faintActive=ok and value==true
end
if b.fainted and not faintActive then return false end
if type(battle.fxHidden)=="function" then
local ok,hidden=pcall(battle.fxHidden,battle,b)
if ok and hidden then return false end
end
return true
end










local function actorVisible(context,side,actor)
local battle=context and context.battle
local b=liveBattler(context,side)





if not (battle and b) then return false end
local compat=V.GenerationCompat
if compat and type(compat.isEmptyBattler)=="function" and compat.isEmptyBattler(b) then return false end
if doublesOpeningPending(context) then return false end
local sourceReturn=P.faintReturns and P.faintReturns[side]
local RP=V and V.ReleasePresentation
if sourceReturn and RP and type(RP.faintActorVisible)=="function" then
local okReturn,override=pcall(RP.faintActorVisible,sourceReturn,side)
if okReturn and override==false then return false end
end
local wh=V and V.WazaHandlers
if wh and type(wh.actorVisible)=="function" and not (actor and (actor.state=="faint" or actor.pendingFaint)) then
local okW,override=pcall(wh.actorVisible,wh,side)
if okW and override==false then return false end
end
if side=="enemy" then
if PlayerTrainer and type(PlayerTrainer.captureHidesEnemy)=="function" then
local okHide,hide=pcall(PlayerTrainer.captureHidesEnemy,PlayerTrainer,context)
if okHide and hide then return false end
end
if battle.showEnemyTrainer then return false end
if battle.enemySendingOut then
local scale=growScale(context,b)
if not (scale and scale>0) then return false end
end
else
if battle.showPlayerBack or battle.safari or battle.demo then return false end
if battle.sendingOut then
local scale=growScale(context,b)
if not (scale and scale>0) then return false end
end
end



local structural=b.invulnerable==true or (b.mon and b.mon.volatile or {}).vanished==true
if actorStructuralHide(actor) and type(battle.actorHidden)=="function" then
local ok,hidden=pcall(battle.actorHidden,battle,b)
structural=structural or (ok and hidden==true)
end
if structural then


local departing=actor and actor.cbeStructuralDeparture and (actor.action or actor.pendingAttack)
if not departing then return false end
elseif actor then actor.cbeStructuralDeparture=nil end

if b.fainted then





if actor and (actor.state=="hit" or actor.pendingFaint) then return true end
local faintActive=false
if type(battle.fxFaintActive)=="function" then
local ok,value=pcall(battle.fxFaintActive,battle,b)
faintActive=ok and value==true
end
if faintActive then return actor~=nil end



if actor and actor.state=="faint" then
if type(actor.terminalComplete)=="function" then
local ok,done=pcall(actor.terminalComplete,actor)
if ok then return not done end
end
return true
end



return actor~=nil
end
return true
end

growScale=function(context,b)
local battle=context and context.battle
if not (battle and b and type(battle.growInScale)=="function") then return nil end
local ok,value=pcall(battle.growInScale,battle,b)
if not (ok and type(value)=="number") then return nil end
return math.max(0,math.min(1,value))
end

local function faintProgress(context,b)
local battle=context and context.battle
if not (battle and b and type(battle.fxFaintActive)=="function") then return nil end
local ok,active=pcall(battle.fxFaintActive,battle,b)
if not (ok and active) then return nil end





local off=0
if type(battle.fxFaintOffset)=="function" then
local okOff,value=pcall(battle.fxFaintOffset,battle,b,1)
if okOff and type(value)=="number" then off=value end
end
return math.max(0,math.min(1,off/56))
end

local function actorGoneByBattle(context,side,b,actor)
local battle=context and context.battle
if not (battle and b) then return true end




if b.fainted==true then



local RP=V and V.ReleasePresentation
local sourceReturn=P.faintReturns and P.faintReturns[side]
if sourceReturn and RP and type(RP.faintComplete)=="function" then
local okReturn,done=pcall(RP.faintComplete,sourceReturn)
if okReturn then return done==true end
return false
end



if actor and (actor.state=="hit" or actor.pendingFaint) then return false end
if actor and actor.state=="faint" then
if faintProgress(context,b)~=nil then return false end
if type(actor.terminalComplete)=="function" then
local ok,done=pcall(actor.terminalComplete,actor)
if ok then return done end
end
return false
end



return actor==nil
end
return false
end




local function syncStadiumActor(context,side)
local record=P.stadiumActors[side]
if not record then return nil end
local battler=liveBattler(context,side)
if battler~=record.battler then
local sourceReturn=P.faintReturns and P.faintReturns[side]
local RP=V and V.ReleasePresentation
if sourceReturn and RP and type(RP.faintComplete)=="function" then
local okReturn,done=pcall(RP.faintComplete,sourceReturn)



if not okReturn or done~=true then return record.actor end




releaseStadiumActor(side,"faint-complete")
return nil
end





local newDex,newVariant=dexFor(context,battler)
if tonumber(newDex)==tonumber(record.dex) and tostring(newVariant)==tostring(record.variant) then
record.battler=battler
else
retireStadiumActor(side,"replacement")
return nil
end
end
if actorGoneByBattle(context,side,battler,record.actor) then
releaseStadiumActor(side,battler and battler.fainted and "faint-complete" or "hidden")
return nil
end
return record.actor
end

local function driveSpawn(context,side,actor)
if not actor then return end
local battler=liveBattler(context,side)
local scale=growScale(context,battler)
if scale==nil then scale=1 end
if side=="enemy" and PlayerTrainer and type(PlayerTrainer.captureEnemyScale)=="function" then
local okCapture,captureScale=pcall(PlayerTrainer.captureEnemyScale,PlayerTrainer,context)
if okCapture and tonumber(captureScale) then scale=scale*math.max(0,math.min(1,tonumber(captureScale))) end
end
if type(actor.spawn)=="function" then
pcall(actor.spawn,actor,scale,{side=side,context=context,battler=battler})
elseif scale>=1 and type(actor.idle)=="function" then
pcall(actor.idle,actor)
end
local record=P.stadiumActors[side]
if record then record.state=scale<1 and "spawn" or "idle" end
end

local function driveRetiringActor(context,record)
local actor=record and record.actor
if not actor then return end
local battle=context and context.battle
if actor.state=="recall" and battle and type(battle.shrinkOutScale)=="function"
and record.battler and type(actor.setRecallScale)=="function" then
local ok,scale=pcall(battle.shrinkOutScale,battle,record.battler)
if ok and type(scale)=="number" then
pcall(actor.setRecallScale,actor,scale)
end
end
end

local EnginePokemonSprites,EngineAssets
local function engineResolvedSprite(context,side,b,current)






local mon=b and b.mon
local game=(context and context.game) or (context and context.battle and context.battle.game)
local data=game and game.data
local species=mon and mon.species
if not (data and species) then return current,false end
local req=V.engineRequire or require
if EnginePokemonSprites==nil then
local ok,value=pcall(req,"src.pokemon.Sprites")
EnginePokemonSprites=ok and value or false
end
if EngineAssets==nil then
local ok,value=pcall(req,"src.render.Assets")
EngineAssets=ok and value or false
end
if not (type(EnginePokemonSprites)=="table" and type(EnginePokemonSprites.path)=="function"
and type(EngineAssets)=="table" and type(EngineAssets.image)=="function") then
return current,false
end
local def=data.pokemon and data.pokemon[species]
local facing=side=="player" and "back" or "front"
local vanilla=def and (facing=="back" and def.spriteBack or def.spriteFront) or nil
local ok,path=pcall(EnginePokemonSprites.path,data,species,facing,{mon=mon,kind="battle"})
if not ok or type(path)~="string" or path=="" then return current,false end


if vanilla and path==vanilla then return current,false end
local okImage,resolved=pcall(EngineAssets.image,path)
if not (okImage and resolved and type(resolved.getDimensions)=="function") then
return current,false
end
if resolved.setFilter then pcall(resolved.setFilter,resolved,"nearest","nearest") end
return resolved,true
end

local function imageFor(context,side)
if not visible(context,side) then return nil end




local battleArtOwns=syncBattleArtSpecies(context,0,false)
local battle=context.battle
local b=liveBattler(context,side)
local image=b and b.sprite
if image and type(battle.picImage)=="function" then
local ok,resolved=pcall(battle.picImage,battle,image)
if ok and resolved then image=resolved end
end




local seamOwned=false
local spriteApi,spriteHandle
P.spriteError=nil

if not battleArtOwns then
local seamImage
seamImage,seamOwned=engineResolvedSprite(context,side,b,image)
if seamOwned then image=seamImage end





spriteApi,spriteHandle=portableSpriteService(context)
P.spriteApi=spriteApi
if spriteHandle then
P.spriteOwner=spriteHandle.id
elseif seamOwned then
P.spriteOwner="engine:pokemon.sprite"
elseif not battleArtWantsWorldSprites() then
P.spriteOwner=nil
end
if spriteApi then
local ok,resolved=pcall(spriteApi.resolve,context,side,b,image)
if ok then
if type(resolved)=="table" and type(resolved.getDimensions)~="function"
and resolved.image~=nil then resolved=resolved.image end
if resolved~=nil and resolved~=false then image=resolved end
else
P.spriteError=tostring(resolved)
end
end
else
P.spriteApi=nil
end
if not (image and type(image.getDimensions)=="function") then return nil end
return image,b
end



local SIDES_EP={"enemy","player"}
local SIDES_PE={"player","enemy"}



local faintQuad=nil

local function anchor(context,side)
local arena=context and context.arena
local p=arena and arena[side]
if type(p)~="table" then return nil end
local x,z=tonumber(p[1]),tonumber(p[2])
if not (x and z) then return nil end
return x,z
end

local function project(context,x,y,z)
local fn=context and context.services and context.services.project
if type(fn)~="function" then return nil end
local ok,sx,sy=pcall(fn,x,y,z)
if not ok or type(sx)~="number" or type(sy)~="number" then return nil end
return sx,sy
end






local MOVE_FX_PIXEL=[[
extern vec4 cbePrim;
extern vec4 cbeEnv;
extern float cbePrimEnv;
extern float cbeAlphaMode;
extern float cbeAlphaP1;
extern float cbeAlphaP2;
extern float cbeIntensityAlpha;
bool cbeCmp(float a, float r, float mode) {
  float eps=0.5/255.0;
  if (mode < 0.5) return false;
  if (mode < 1.5) return a < r;
  if (mode < 2.5) return abs(a-r) <= eps;
  if (mode < 3.5) return a <= r+eps;
  if (mode < 4.5) return a > r;
  if (mode < 5.5) return abs(a-r) > eps;
  if (mode < 6.5) return a+eps >= r;
  return true;
}
bool cbeAlphaPass(float a) {
  float c0=mod(floor(cbeAlphaMode/8.0),8.0);
  float op=floor(cbeAlphaMode/64.0);
  float c1=mod(cbeAlphaMode,8.0);
  bool a0=cbeCmp(a,cbeAlphaP1,c0);
  bool a1=cbeCmp(a,cbeAlphaP2,c1);
  if (op < 0.5) return a0 && a1;
  if (op < 1.5) return a0 || a1;
  if (op < 2.5) return a0 != a1;
  return a0 == a1;
}
vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
  vec4 t=Texel(texture,uv);
  // GX I4/I8 replicate intensity into alpha too. The retained source cache
  // stores those two formats with opaque alpha; recover their exact format
  // semantics here without recoloring or invalidating unrelated GX assets.
  if (cbeIntensityAlpha > 0.5) t.a=t.r;
  vec4 outColor;
  if (cbePrimEnv > 0.5) {
    // GX particle Prim/Env textures use intensity as the interpolation weight.
    // Preserve that source gradient instead of flattening I4/I8 into a white
    // alpha mask and applying one CBE-authored tint.
    float k=clamp(t.r,0.0,1.0);
    vec3 rgb=mix(cbeEnv.rgb,cbePrim.rgb,k);
    float a=t.a*mix(cbeEnv.a,cbePrim.a,k);
    outColor=vec4(rgb,a)*color;
  } else {
    outColor=vec4(t.rgb*cbePrim.rgb,t.a*cbePrim.a)*color;
  }
  if (!cbeAlphaPass(outColor.a)) discard;
  return outColor;
}
]]
local function particleIntensityAlpha(spec)
local fmt=type(spec)=="table" and tonumber(spec.fmt)
return (fmt==0 or fmt==1) and 1 or 0
end

local function moveFxShader()
if P.moveFxShader~=nil then return P.moveFxShader or nil end
if not (love and love.graphics and love.graphics.newShader) then P.moveFxShader=false;return nil end
local ok,sh=pcall(love.graphics.newShader,MOVE_FX_PIXEL)
P.moveFxShader=ok and sh or false
if not ok then P.moveFxError=tostring(sh) end
return ok and sh or nil
end

local function moveFxImage(spec)
if not (GeneratedAssets and spec and spec.path and love and love.image and love.graphics) then return nil end
local cached=P.moveFxImages[spec.path]
if cached~=nil then return cached or nil end
local bytes=GeneratedAssets.read(spec.path)


if type(bytes)~="string" then return nil end
local okData,data=pcall(love.image.newImageData,spec.w,spec.h,"rgba8",bytes)
if not okData or not data then return nil end
local okImg,img=pcall(love.graphics.newImage,data)
if not okImg or not img then return nil end
if not pcall(img.setFilter,img,"linear","linear",8) then pcall(img.setFilter,img,"linear","linear",1) end
P.moveFxImages[spec.path]=img
return img
end
function P.prewarmMoveFxSpec(spec)
for _,texture in ipairs(spec and spec.textures or {}) do
if V.WorkBudget then V.WorkBudget.checkpoint("Uploading move particles") end
moveFxImage(texture)
end
moveFxShader()
end

local refreshMoveFxBasis
local sourceRootAttachment

local function roleHasSource(spec,role)
return MoveFXVM and type(MoveFXVM.hasRole)=="function" and MoveFXVM.hasRole(spec,role)
end
local function roleHasTimeline(spec,role)
if not (WazaSequence and type(WazaSequence.hasTimeline)=="function") then return false end
local ok,has=pcall(WazaSequence.hasTimeline,WazaSequence,spec,role)
return ok and has==true
end







local PKX_SLOT_BY_INDEX={
[0]="idle",[1]="specialA",[2]="physicalA",[3]="physicalB",[4]="physicalC",
[5]="physicalD",[6]="specialB",[7]="physicalE",[8]="damage",[9]="damageHeavy",
[10]="faint",[11]="extra1",[12]="specialC",[13]="extra2",[14]="extra3",
[15]="extra4",[16]="takeFlight",
}
local function sourceNativeSlot(spec,role)
if V.WazaPhasePolicy then spec=V.WazaPhasePolicy.select(spec) end
role=tostring(role or "attack")
local fallback
for _,phase in ipairs(type(spec)=="table" and (spec.wazaPhases or {}) or {}) do
local name=tostring(phase.name or phase.phase or "all"):lower()
local phaseRole=(name:match("^damage") or name=="status") and "damage" or "attack"
if phaseRole==role then
local kind=tonumber(phase.sequenceKind)
if kind and kind>=0 and kind<=16 and math.floor(kind)==kind then
local slot=PKX_SLOT_BY_INDEX[kind]
if slot then



if #(phase.entries or {})>0 then return slot,kind,phase end
fallback=fallback or {slot,kind,phase}
end
end
end
end
if fallback then return fallback[1],fallback[2],fallback[3] end
return nil,nil,nil
end
local function wazaEntryKey(entry)
if type(entry)~="table" then return nil end
return table.concat({tostring(entry.phase or ""),tostring(entry.identifier or ""),
tostring(entry.index or ""),tostring(entry.offset or "")},"|")
end

local function stageMoveFx(context,side,spec,target,role,wazaEntry,wazaSerial,activeMoveId)
role=role or "attack"
local executable=MoveFXVM and type(MoveFXVM.start)=="function"
and ((type(wazaEntry)=="table" and type(MoveFXVM.hasEntry)=="function" and MoveFXVM.hasEntry(spec,wazaEntry,role))
or (wazaEntry==nil and roleHasSource(spec,role)))
if not (side and cbeFxWorldActive(context) and type(spec)=="table"
and type(spec.textures)=="table" and #spec.textures>0
and type(spec.generatorPrograms)=="table" and #spec.generatorPrograms>0
and executable) then
return false
end
local imagesByBank={};local imagesByBankContainer={};local imagesByBankContainerIndex={}
local indexedBanks={};local imageCount=0;local missingImages=0
local wantedBank=type(wazaEntry)=="table" and tonumber(wazaEntry.bank)
for _,tex in ipairs(spec.textures) do
if not wantedBank or tonumber(tex.bank)==wantedBank then
local bank=tonumber(tex.bank) or 1
local container=tonumber(tex.container)
local texture=tonumber(tex.texture)
if container and texture then indexedBanks[bank]=true end
local img=moveFxImage(tex)
if not img then missingImages=missingImages+1 else
local wrapped={image=img,spec=tex}




imagesByBank[bank]=imagesByBank[bank] or {}
imagesByBank[bank][#imagesByBank[bank]+1]=wrapped
if container and texture then
imagesByBankContainerIndex[bank]=imagesByBankContainerIndex[bank] or {}
imagesByBankContainerIndex[bank][container]=imagesByBankContainerIndex[bank][container] or {}
imagesByBankContainerIndex[bank][container][texture]=wrapped
else
container=container or 0
imagesByBankContainer[bank]=imagesByBankContainer[bank] or {}
imagesByBankContainer[bank][container]=imagesByBankContainer[bank][container] or {}
imagesByBankContainer[bank][container][#imagesByBankContainer[bank][container]+1]=wrapped
end
imageCount=imageCount+1
end
end
end
for _,list in pairs(imagesByBank) do
table.sort(list,function(a,b)
local ac,bc=tonumber(a.spec.container) or 0,tonumber(b.spec.container) or 0
if ac~=bc then return ac<bc end
return (tonumber(a.spec.texture) or 0)<(tonumber(b.spec.texture) or 0)
end)
end
for _,containers in pairs(imagesByBankContainer) do
for _,list in pairs(containers) do
table.sort(list,function(a,b)
return (tonumber(a.spec.texture) or 0)<(tonumber(b.spec.texture) or 0)
end)
end
end
if imageCount==0 or missingImages>0 then
P.moveFxError="source GPT1 textures failed to create LÖVE images ("..tostring(missingImages).." missing)"
return false
end



local entryKey=wazaEntryKey(wazaEntry)
if wazaSerial and entryKey then
for _,old in ipairs(P.moveFxActive) do
if old.wazaSerial==wazaSerial and old.wazaEntryKey==entryKey then return true,old end
end
end







for i=#P.moveFxActive,1,-1 do
local old=P.moveFxActive[i]
if role=="attack" and old.side==side and (not wazaSerial or old.wazaSerial~=wazaSerial) then
table.remove(P.moveFxActive,i)
elseif not wazaSerial and role=="damage" and old.side==side and old.spec==spec and old.role=="damage"
and old.vm and (tonumber(old.vm.age) or 1)<0.065 then
return true
end
end

local okVm,vm=pcall(MoveFXVM.start,spec,{role=role,entry=wazaEntry,
sequenceStartHandled=wazaEntry~=nil})
if not okVm or type(vm)~="table" or (#(vm.emitters or {})==0 and vm.pendingRoot==nil) then
P.moveFxError=tostring(okVm and "source GPT1 phase has no executable generators" or vm);return false
end
P.moveFxError=nil
local active={
context=context,side=side,target=target or (side=="player" and "enemy" or "player"),spec=spec,role=role,moveId=tonumber(activeMoveId),
vm=vm,imagesByBank=imagesByBank,imagesByBankContainer=imagesByBankContainer,
imagesByBankContainerIndex=imagesByBankContainerIndex,indexedBanks=indexedBanks,
wazaEntry=wazaEntry,wazaSerial=wazaSerial,wazaEntryKey=entryKey,
releaseGeometry=spec.releaseGeometry,
rootAttachment=(type(wazaEntry)=="table" and tonumber(wazaEntry.attachment)) or sourceRootAttachment(spec,role),
}
P.moveFxActive[#P.moveFxActive+1]=active
refreshMoveFxBasis(context,active)
return true,active
end


function P:stageReleaseParticles(context,side,spec,entry,geometry,serial)
local view={};for k,v in pairs(spec)do view[k]=v end;view.releaseGeometry=geometry
return stageMoveFx(context,side,view,nil,"attack",entry,serial)
end
local wazaHandlersInstalled=false
local function installWazaHandlers()
if wazaHandlersInstalled or not (WazaSequence and type(WazaSequence.registerHandler)=="function") then return end
local handler={
start=function(context,instance,entry,event,state)
local id=tonumber(instance.moveId) or (instance.spec.phaseSelection and instance.spec.phaseSelection.moveId) or instance.spec.moveId
local ok,fx=stageMoveFx(context,instance.side,instance.spec,instance.target,instance.role,entry,instance.serial,id)
if ok and fx then
fx.wazaInstance=instance;fx.wazaState=state
state.cbeParticle=fx;state.cbeParticleFrame=state.startFrame
end
return ok
end,
update=function(context,instance,entry,frame,state)
local fx=state.cbeParticle
if not fx or not fx.vm or fx.vm.done then return false end
refreshMoveFxBasis(context,fx)



local delta=math.max(0,frame-(state.cbeParticleFrame or frame))
state.cbeParticleFrame=frame
if delta==0 then return true end
local ok,alive=pcall(MoveFXVM.update,fx.vm,delta/60)
if not ok then P.moveFxError=tostring(alive);fx.vm.done=true;return false end
if fx.vm.truncated then P.moveFxError="Source particle watchdog: "..tostring(instance.moveId) end
return alive
end,


finish=function() return true end,



cancel=function(context,instance)
for i=#P.moveFxActive,1,-1 do
if P.moveFxActive[i].wazaSerial==instance.serial then table.remove(P.moveFxActive,i) end
end
return true
end,
}
WazaSequence:registerHandler("particle","cbe-gpt1",handler)
wazaHandlersInstalled=true
end

local function actorWazaTiming(actor)
if actor and type(actor.wazaTimingPoints)=="function" then
local ok,points=pcall(actor.wazaTimingPoints,actor)
if ok and type(points)=="table" then return points end
end
return nil
end

local function startWazaSequence(context,side,spec,target,role,moveId,move)
if not (WazaSequence and type(WazaSequence.hasTimeline)=="function" and type(WazaSequence.start)=="function") then return false end
installWazaHandlers()
local okHas,has=pcall(WazaSequence.hasTimeline,WazaSequence,spec,role)
if not okHas or not has then return false end
local timingSide=(role=="damage" and target) or side
local timingActor=timingSide and P.stadiumActors[timingSide] and P.stadiumActors[timingSide].actor or nil
if not timingActor and timingSide then timingActor=stadiumActor(context,timingSide) end
if role=="attack" and P.mode=="stadium" then




if not timingActor or timingActor.action~="attack" or not timingActor.nativeSlot then
P.moveFxError="source PKX attack timing row unavailable; Waza attack timeline withheld"
return false
end
end
local points=actorWazaTiming(timingActor)
local presentationFrames
if timingActor and type(timingActor.stateDuration)=="function" then
local stateKind=role=="damage" and "hit" or "attack"
local okDur,dur=pcall(timingActor.stateDuration,timingActor,stateKind)
if okDur and tonumber(dur) then presentationFrames=math.floor(math.max(0,tonumber(dur))*60+.5) end
end
local ok,inst,err=pcall(WazaSequence.start,WazaSequence,context,side,spec,{role=role,target=target,moveId=moveId,move=move,
globalTimingPoints=points,presentationFrames=presentationFrames})
if not ok or type(inst)~="table" then
P.moveFxError=tostring(ok and (err or "WazaSequence did not start") or inst)
return false
end



return true
end

local function startMoveFx(context,side,moveId,move,role,target)
if not (MoveFX and side and ourArena(context)) then return false end
local spec,err
if type(MoveFX.peek)=="function" then
local ok,value,why=pcall(MoveFX.peek,moveId,move)
if ok and type(value)=="table" then spec=value else err=why or value end
end
if not spec then
if type(MoveFX.queuePrefetch)=="function" then pcall(MoveFX.queuePrefetch,moveId,move,context and context.battle) end
P.moveFxError=tostring(err or "source WZX cache not prepared; queued without blocking battle")
return false
end
if not (type(spec.generatorPrograms)=="table" and #spec.generatorPrograms>0) then
P.moveFxError=tostring(err or (spec and spec.note) or "source WZX has no decoded GPT1 program bank")
return false
end
return stageMoveFx(context,side,spec,target,role or "attack")
end




local function directedMoveFx(context)
if not (Director and type(Director.consumeFxCue)=="function") then return false end
for _,side in ipairs(SIDES_PE) do pcall(Director.consumeFxCue,Director,context,side) end
return false
end

local function updateMoveFx(context,dt)
local step=math.max(0,tonumber(dt) or 0)
for i=#P.moveFxActive,1,-1 do
local fx=P.moveFxActive[i]
refreshMoveFxBasis(context,fx)



local advance=step
if fx.wazaInstance and not fx.wazaInstance.done then advance=0 end
if fx.wazaInstance and fx.wazaInstance.done and not fx.wazaDetached then
fx.wazaDetached=true;advance=0
end
local ok,alive=pcall(MoveFXVM.update,fx.vm,advance)
if not ok then
P.moveFxError=tostring(alive);table.remove(P.moveFxActive,i)
elseif alive==false or (fx.vm and fx.vm.done) then
table.remove(P.moveFxActive,i)
end
end
end

local BODY_SLOT_NAMES={
"origin","mouth","chest","tail","eye_left","eye_right","hand_left","hand_right",
"additional_1","additional_2","additional_3","additional_4","foot_left","foot_right","center","additional_5",
}

local function actorAttachmentWorld(side,name)
local rec=P.stadiumActors and P.stadiumActors[side]
local actor=rec and rec.actor
local memo=P.doublesAttachmentMemo
local row=memo and actor and memo[actor]
if row and row[name]~=nil then return row[name] or nil,actor end
if memo and actor and not row then row={};memo[actor]=row end
if actor and type(actor.attachment)=="function" then
local ok,a=pcall(actor.attachment,actor,name)
local p=ok and type(a)=="table" and a.position
if type(p)=="table" and tonumber(p[1]) and tonumber(p[2]) and tonumber(p[3]) then
local point={tonumber(p[1]),tonumber(p[2]),tonumber(p[3])}
if row then row[name]=point end
return point,actor
end
end
if row then row[name]=false end
return nil,actor
end





local function moveFxWorldPoint(context,side,name)
local p,actor=actorAttachmentWorld(side,name or "center")
if not p and name~="chest" then p,actor=actorAttachmentWorld(side,"chest") end
if p then return p,actor,true end
local x,z=anchor(context,side);if not x then return nil end
local arena=context.arena or {};local k=math.max(.08,tonumber(arena.figureScale) or .38)
local rel=tonumber(actor and actor.physicalScale) or .72
rel=math.max(.30,math.min(2.20,rel))
local y=13*(rel/.72)
y=math.max(6.6,math.min(31,y))
return {x,y/k,z},actor,false
end

local function actorRootWorld(context,side,actor)



local r=actor and actor.rootPosition
if type(r)=="table" and tonumber(r[1]) and tonumber(r[2]) and tonumber(r[3]) then
return {tonumber(r[1]),tonumber(r[2]),tonumber(r[3])}
end
local m=actor and actor.worldMatrix
if type(m)=="table" and tonumber(m[4]) and tonumber(m[8]) and tonumber(m[12]) then
return {tonumber(m[4]),tonumber(m[8]),tonumber(m[12])}
end
local x,z=anchor(context,side);if not x then return nil end
return {x,tonumber(context and context.groundY) or 0,z}
end

local function projectMoveFxWorld(context,p)
if not (p and p[1]) then return nil end


return project(context,p[1] or 0,p[2] or 0,p[3] or 0)
end

function P:projectWazaWorld(context,p) return projectMoveFxWorld(context,p) end

local function vsub(a,b)return {(a[1] or 0)-(b[1] or 0),(a[2] or 0)-(b[2] or 0),(a[3] or 0)-(b[3] or 0)} end
local function vdot(a,b)return (a[1] or 0)*(b[1] or 0)+(a[2] or 0)*(b[2] or 0)+(a[3] or 0)*(b[3] or 0) end
local function vlen(v)return math.sqrt(vdot(v,v)) end
local function vnorm(v)
local l=vlen(v);if l<1e-8 then return {0,0,1} end
return {v[1]/l,v[2]/l,v[3]/l}
end
local function vcross(a,b)return {(a[2] or 0)*(b[3] or 0)-(a[3] or 0)*(b[2] or 0),(a[3] or 0)*(b[1] or 0)-(a[1] or 0)*(b[3] or 0),(a[1] or 0)*(b[2] or 0)-(a[2] or 0)*(b[1] or 0)} end
local function effectBasis(source,target)




local delta=vsub(target,source)
local flat={delta[1] or 0,0,delta[3] or 0}
local forward=vnorm(vlen(flat)>1e-6 and flat or delta)
local up={0,1,0}
local right=vnorm(vcross(up,forward))
if vlen(right)<1e-6 then right={1,0,0} end
forward=vnorm(vcross(right,up))
return right,up,forward
end

local GROUND_FIELD_MOVES={
[89]=true,
[222]=true,
}
local function actorVisualHeight(actor)
local h=tonumber(actor and actor.height) or 16
local scale=tonumber(actor and actor.worldScale) or 1
return math.max(.25,h*scale)
end
local RETAIL_EFFECT_OWNER_SCALES={[-2]=.5,[-1]=.75,[0]=1,[1]=1.333299994468689,[2]=2,[3]=3.25}
local function sourceOwnerUnit(actor,opts)
if not actor then return nil end
local metadata=actor.sourceMetadata
local selector=metadata and tonumber(metadata.scaleSelector~=nil and metadata.scaleSelector or metadata.sequenceKind)
if selector==nil then return nil end




if math.floor((tonumber(opts.flags) or 0)/4)%2==1 then return nil end
local scene=actor.scene or {}
local norm=scene.sourceNormalization
if not norm then
local bound=scene.retailWazaOwnerBound
norm=bound and bound.exact==true and bound.sourceToCache or nil
end
local cachePerSource=norm and tonumber(norm.s)
if not (cachePerSource and cachePerSource>0) then
local scale=V.PokemonSourceScale
if scale and type(scale.sourcePerCache)=='function' then
local perCache=scale.sourcePerCache(scene,actor.dex,V.ColosseumDex)
if perCache and perCache>0 then cachePerSource=1/perCache end
end
end
if not (cachePerSource and cachePerSource>0) then return nil end
local pt=tonumber(opts.positionType)
if opts.modelEntry and (pt==2 or pt==4 or pt==5 or pt==6) then


local inherited=cachePerSource*(tonumber(actor.worldScale) or 1)
if inherited>0 and inherited<math.huge then return inherited end
return nil
end
local multiplier=RETAIL_EFFECT_OWNER_SCALES[selector] or 1
local id=tonumber(opts.moveId)
local group=tonumber(opts.resourceGroup) or (opts.role=='damage' and 2 or 1)


if id==177 then multiplier=multiplier*.5
elseif id==196 then
if group==1 then multiplier=multiplier*.4000000059604645
elseif group==2 then multiplier=multiplier*.5 end
elseif id==250 then
if group==1 then multiplier=multiplier*.625
elseif group==2 then multiplier=multiplier*.6150000095367432 end
elseif id==281 or ((id==307 or id==315) and group==2) then multiplier=multiplier*.6669999957084656
elseif id==323 and group==2 then multiplier=multiplier*.5550000071525574
elseif (id==329 or id==354) and group==2 then multiplier=multiplier*.7139999866485596 end
local unit=cachePerSource*(tonumber(actor.worldScale) or 1)*multiplier
if unit>0 and unit<math.huge then return unit end
end


local AIMED_MOVES={[53]=true,[55]=true,[56]=true,[58]=true,[59]=true,[60]=true,[61]=true,[62]=true,[63]=true,[82]=true,[85]=true,[190]=true,[225]=true}





local PARTICLE_TRANSIT_SPAN={











[53]={sourceBank=1,sourceState=0,selector=23,
span=2*0.9800000190734863*(1-0.9800000190734863^60)/(1-0.9800000190734863),
phases={attack=true,sp1=true}},




[55]={sourceBank=1,selector=24,span=60,phases={attack=true,sp1=true}},
[61]={sourceBank=1,selector=22,span=1.2999999523162842*50,phases={attack=true,sp1=true}},



[190]={sourceBank=1,selector=45,span=60,phases={attack=true}},
}











local BLIZZARD_PARTICLE_OWNER=2
local BLIZZARD_CORES={[11]={selector=11,span=57},[12]={selector=12,span=25}}
local function transitProfile(moveId,entry)
local id=tonumber(moveId)
if type(entry)~="table" then return end
if SourceTravel and type(SourceTravel.particleProfile)=="function" then
local profile=SourceTravel.particleProfile(id,entry)
if profile then return profile end
end





local sourceBank=tonumber(entry.sourceBank);local selector=tonumber(entry.selector or entry.rootRef)
if id==59 then
if sourceBank~=1 or tonumber(entry.state)~=BLIZZARD_PARTICLE_OWNER then return nil end
return BLIZZARD_CORES[selector]
end






local profile=PARTICLE_TRANSIT_SPAN[id]
if profile and profile.sourceBank and sourceBank~=profile.sourceBank then return nil end
if profile and profile.sourceState~=nil and tonumber(entry.state)~=profile.sourceState then return nil end
return profile
end
local function particleTransitSpan(moveId,role,entry)
local profile=transitProfile(moveId,entry)
if not profile or tostring(role or "attack")~="attack" or type(entry)~="table" then return 100 end
local phase=tostring(entry.phase or "attack"):lower()
if not profile.sourceExact then
if profile.phases and profile.phases[phase]~=true then return 100 end
if not profile.phases and phase~="attack" and phase~="sp1" then return 100 end
end
if (tonumber(entry.flags) or 0)%2==1 then return 100 end
if tonumber(entry.selector or entry.rootRef)~=profile.selector then return 100 end
return profile.span
end

local function combatGeometry(context,side,target,attachment,opts)
opts=type(opts)=="table" and opts or {}
local moveId=tonumber(opts.moveId)
local attackRole=tostring(opts.role or "attack")=="attack"
local particleProfile=opts.sourceStrict==true and attackRole and transitProfile(moveId,opts.particleEntry) or nil
local modelProfile
if opts.sourceStrict==true and attackRole and SourceTravel and type(SourceTravel.modelProfile)=="function" then
modelProfile=SourceTravel.modelProfile(moveId,opts.modelEntry)
end


local aimed=particleProfile~=nil or modelProfile~=nil
or (SourceTravel==nil and opts.sourceStrict==true and attackRole and AIMED_MOVES[moveId]==true)
or (opts.sourceStrict~=true and tostring(opts.style or ''):lower()=='projectile')
if SourceTravel==nil and (moveId==59 or moveId==85) then
aimed=aimed and transitProfile(moveId,opts.particleEntry)~=nil
end
local fieldWave=opts.sourceStrict==true and moveId==57 and attackRole
local slot=tonumber(attachment)
local name=(slot and slot>=0 and slot<#BODY_SLOT_NAMES) and BODY_SLOT_NAMES[math.floor(slot)+1] or "center"
local other=target or (side=="player" and "enemy" or "player")
local origin,actor=moveFxWorldPoint(context,side,name)
local goal,targetActor=moveFxWorldPoint(context,other,"center")
if not (origin and goal) then return nil end




local ownerActor=actor




if opts.ownerRoot==true then
local root=actorRootWorld(context,side,ownerActor)
if root then origin=root end
end






local transformSelector
if opts.sourceStrict and opts.positionType~=nil then
local pt=math.floor(tonumber(opts.positionType) or -1)
transformSelector=(pt>=0 and pt<=6) and (pt+1) or 0
local inheritsPartPosition=(transformSelector==1 or transformSelector==4 or transformSelector==6 or transformSelector==7)
if not inheritsPartPosition then
local root=actorRootWorld(context,side,actor)
if root then origin=root end
end
end

local originSide=side

if opts.ownerRoot~=true and opts.sourceStrict and moveId==94 and tostring(opts.role or 'attack')=='attack' then
origin,goal=goal,origin;actor,targetActor=targetActor,actor;originSide=other
end
local sourceHeight=actorVisualHeight(actor)
local targetHeight=actorVisualHeight(targetActor)
local spreadWidth
if aimed and moveId==59 and type(context.cbeWazaTargets)=="table" and #context.cbeWazaTargets>1 then
local targets=context.cbeWazaTargets;local x,z=0,0
for _,p in ipairs(targets)do x=x+p[1];z=z+p[2]end
goal={x/#targets,goal[2],z/#targets};spreadWidth=0
for i,p in ipairs(targets)do for j=1,i-1 do local q=targets[j]
spreadWidth=math.max(spreadWidth,math.sqrt((p[1]-q[1])^2+(p[2]-q[2])^2))
end end
end
local fullFightDistance=vlen(vsub(goal,origin))
local sourceStrict=opts.sourceStrict==true
local style=sourceStrict and "source" or tostring(opts.style or ""):lower()
local role=tostring(opts.role or "attack"):lower()


local groundField=(not sourceStrict) and role=="attack" and GROUND_FIELD_MOVES[moveId]==true





if groundField then
local sx,sz=anchor(context,side);local tx,tz=anchor(context,other)
if sx and tx then
local gy=tonumber(context and context.groundY) or 0
origin={(sx+tx)*.5,gy,(sz+tz)*.5}
goal={tx,gy,tz}
fullFightDistance=math.sqrt((tx-sx)^2+(tz-sz)^2)
else
local gy=tonumber(context and context.groundY) or 0
origin={(origin[1]+goal[1])*.5,gy,(origin[3]+goal[3])*.5}
end
end

if fieldWave and opts.ownerRoot~=true then
local sx,sz=anchor(context,side);local tx,tz=anchor(context,other)
local targets=context and context.cbeWazaTargets
if type(targets)=="table" and #targets>1 then
local ax,az=0,0;for _,p in ipairs(targets) do ax=ax+p[1];az=az+p[2] end
tx,tz=ax/#targets,az/#targets
end
if sx and tx then
local gy=tonumber(context.groundY) or 0
origin={(sx+tx)*.5,gy,(sz+tz)*.5};goal={tx,gy,tz}
fullFightDistance=math.sqrt((tx-sx)^2+(tz-sz)^2)
end
end
local right,up,forward=effectBasis(origin,goal)
if aimed then
forward=vnorm(vsub(goal,origin));right=vnorm(vcross({0,1,0},forward));up=vnorm(vcross(forward,right))
end
local ownerUnit=sourceStrict and sourceOwnerUnit(actor,opts) or nil
local sourceUnit=ownerUnit or sourceHeight/100
local travelSpan=particleProfile and tonumber(particleProfile.span) or modelProfile and tonumber(modelProfile.reach) or nil
if not travelSpan and aimed then travelSpan=particleTransitSpan(moveId,role,opts.particleEntry) end
local travelUnit=aimed and math.max(.001,fullFightDistance/math.max(.001,travelSpan or 100)) or nil
local units={x=sourceUnit,y=sourceUnit,z=travelUnit or sourceUnit}
if particleProfile or modelProfile then










local fieldUnit=math.max(.001,fullFightDistance/100)
units={x=fieldUnit,y=fieldUnit,z=travelUnit}
end
if spreadWidth then units.x=math.max(units.x,(spreadWidth+sourceHeight*.25)/60) end
if fieldWave then



local u=math.max(.001,fullFightDistance/100);units={x=u,y=u,z=u}
end





if (not sourceStrict) and style=="projectile" then
local fightUnit=math.max(.01,fullFightDistance/100)
units.z=fightUnit
elseif (not sourceStrict) and style=="wave" then
local fightUnit=math.max(.01,fullFightDistance/100)
units.x=math.max(sourceUnit*.80,math.min(sourceUnit*3.0,fullFightDistance/180))
units.z=fightUnit
elseif groundField then
local fieldUnit=math.max(.01,fullFightDistance/100)
units.x=fieldUnit;units.z=fieldUnit
units.y=((sourceHeight+targetHeight)*.5)/100
end








local interactionHeight=math.sqrt(math.max(.01,sourceHeight*targetHeight))
interactionHeight=math.max(math.min(sourceHeight,targetHeight)*.72,
math.min(math.max(sourceHeight,targetHeight)*1.12,interactionHeight))
local referenceHeight
if sourceStrict then referenceHeight=sourceHeight
elseif groundField then referenceHeight=(sourceHeight+targetHeight)*.5
elseif role=="damage" then referenceHeight=sourceHeight
elseif style=="target" then referenceHeight=targetHeight
elseif style=="impact" or style=="contact" then referenceHeight=interactionHeight
else referenceHeight=sourceHeight end

local modelTargetSpan
if sourceStrict then modelTargetSpan=referenceHeight
elseif groundField then modelTargetSpan=math.max(referenceHeight,fullFightDistance*1.08)
elseif style=="wave" then modelTargetSpan=math.max(referenceHeight,fullFightDistance*.82)
elseif style=="projectile" then



local projectileHeight=math.max(sourceHeight*.80,math.min(interactionHeight*1.12,sourceHeight*1.85))
modelTargetSpan=math.max(projectileHeight*.80,math.min(fullFightDistance*.72,projectileHeight*2.55))
elseif role=="damage" then modelTargetSpan=sourceHeight*.92
elseif style=="target" then modelTargetSpan=targetHeight*.92
elseif style=="impact" or style=="contact" then modelTargetSpan=interactionHeight*.86
else modelTargetSpan=referenceHeight end

local scaleActor=opts.ownerRoot==true and ownerActor or actor
local sourceScaleSelector=scaleActor and scaleActor.sourceMetadata
and tonumber(scaleActor.sourceMetadata.scaleSelector~=nil and scaleActor.sourceMetadata.scaleSelector or scaleActor.sourceMetadata.sequenceKind) or nil



local ownerModelYaw=opts.ownerRoot==true and ownerActor and tonumber(ownerActor.worldYaw) or nil
local ownerCameraTiming
local ownerRetailWazaBound
if opts.ownerRoot==true and ownerActor and type(ownerActor.wazaCameraTiming)=="function" then
local okTiming,value=pcall(ownerActor.wazaCameraTiming,ownerActor)
if okTiming and type(value)=="table" and value.exact==true then
ownerCameraTiming=value





ownerCameraTiming.frameShift=0
end
end
if opts.ownerRoot==true and ownerActor and type(ownerActor.retailWazaOwnerBound)=="function" then
local okBound,value=pcall(ownerActor.retailWazaOwnerBound,ownerActor)
if okBound and type(value)=="table" and value.exact==true and value.selectorExact==true then
ownerRetailWazaBound=value
end
end
return {aimed=aimed,fieldWave=fieldWave,originSide=originSide,origin=origin,target=goal,right=right,up=up,forward=forward,actor=actor,targetActor=targetActor,
actorScale=tonumber(actor and actor.worldScale) or 1,attachment=name,style=style,moveId=moveId,role=role,sourceStrict=sourceStrict,
ownerDex=opts.ownerRoot==true and ownerActor and tonumber(ownerActor.dex) or nil,
sourceScaleSelector=sourceScaleSelector,sourceScaleSelectorExact=sourceScaleSelector~=nil,
ownerCameraTiming=ownerCameraTiming,ownerCameraTimingExact=ownerCameraTiming~=nil,
ownerRetailWazaBound=ownerRetailWazaBound,ownerRetailWazaBoundExact=ownerRetailWazaBound~=nil,
ownerModelYaw=ownerModelYaw,ownerModelRotationExact=ownerModelYaw~=nil,
groundField=groundField,sourceVisualHeight=sourceHeight,targetVisualHeight=targetHeight,interactionVisualHeight=interactionHeight,
fightDistance=fullFightDistance,sourceUnits=units,sourceUnitsFromOwner=ownerUnit~=nil,
referenceVisualHeight=referenceHeight,modelTargetSpan=modelTargetSpan,
sourceTravelProfile=particleProfile,sourceModelTravelProfile=modelProfile,sourceModelReach=modelProfile and modelProfile.reach or nil,
sourceTravelFieldScaled=(particleProfile~=nil or modelProfile~=nil),
transformSelector=transformSelector}
end




function P:wazaBasis(context,side,target,attachment,opts)
return combatGeometry(context,side,target,attachment,opts)
end
function P:sourceOwnerUnit(actor,opts) return sourceOwnerUnit(actor,opts or {}) end

local function retailScaleSelector(actor)
local metadata=actor and actor.sourceMetadata
if type(metadata)~="table" then return nil end
local value=metadata.scaleSelector
if value==nil then value=metadata.sequenceKind end
return value~=nil and tonumber(value) or nil
end



function P:retailScaleSelector(actor) return retailScaleSelector(actor) end
function P:retailScaleSelectors()
local out={}
for _,side in ipairs({"player","enemy"}) do
local rec=self.stadiumActors and self.stadiumActors[side]
local selector=rec and retailScaleSelector(rec.actor) or nil
if selector==nil then return out,false end
out[#out+1]=selector
end
return out,#out==2
end

local function unitAxis(unit,key,index)
if type(unit)=="table" then return tonumber(unit[key]) or tonumber(unit[index]) or 1 end
return tonumber(unit) or 1
end
local function localToWorld(origin,right,up,forward,pos,unit)
local ux,uy,uz=unitAxis(unit,"x",1),unitAxis(unit,"y",2),unitAxis(unit,"z",3)
local x=(tonumber(pos and pos[1]) or 0)*ux
local y=(tonumber(pos and pos[2]) or 0)*uy
local z=(tonumber(pos and pos[3]) or 0)*uz
return {
origin[1]+right[1]*x+up[1]*y+forward[1]*z,
origin[2]+right[2]*x+up[2]*y+forward[2]*z,
origin[3]+right[3]*x+up[3]*y+forward[3]*z,
}
end
local function worldToLocal(origin,right,up,forward,p)
local d=vsub(p,origin);return {vdot(d,right),vdot(d,up),vdot(d,forward)}
end





function P:wazaLocalPoint(context,side,target,attachment,pos,opts)
local geometry=combatGeometry(context,side,target,attachment,opts)
if not geometry then return nil end
return localToWorld(geometry.origin,geometry.right,geometry.up,geometry.forward,pos,geometry.sourceUnits),geometry
end

local function moveFxPhaseRole(phase)
phase=tostring(phase or "all"):lower()
return (phase:match("^damage") or phase=="status") and "damage" or "attack"
end

sourceRootAttachment=function(spec,role)
for _,g in ipairs(type(spec)=="table" and (spec.generatorPrograms or {}) or {}) do
if g.root==true and moveFxPhaseRole(g.phase)==role then
local seq=g.sequence
local a=seq and tonumber(seq.attachment)
if a and a>=0 and a<#BODY_SLOT_NAMES then return math.floor(a) end
end
end
return nil
end

refreshMoveFxBasis=function(context,fx)
if not fx then return false end
local originSide=fx.role=="damage" and fx.target or fx.side
local otherSide=originSide==fx.side and fx.target or fx.side
local rootSlot=fx.rootAttachment
if rootSlot==nil then rootSlot=sourceRootAttachment(fx.spec,fx.role);fx.rootAttachment=rootSlot end
local geometry
local linked=fx.wazaEntry and (tonumber(fx.wazaEntry.flags) or 0)%2==1
if linked and fx.wazaInstance and V.WazaHandlers and V.WazaHandlers.linkedParticleFrame then
local frame,why=V.WazaHandlers.linkedParticleFrame(context,fx.wazaInstance,fx.wazaEntry)
if not frame then fx.attachmentError=why;return false end
geometry=frame.basis;fx.modelLinked=true;fx.attachmentError=nil
if fx.vm then fx.vm.emissionTransform=frame.particleTransform;fx.vm.emissionOrigin=nil end
fx.linkedFrame=frame
elseif linked and not fx.wazaInstance then
return false
else
geometry=fx.releaseGeometry or combatGeometry(context,originSide,otherSide,rootSlot,{
moveId=fx.moveId or (fx.spec and fx.spec.moveId),style=fx.spec and fx.spec.style,role=fx.role,
sourceStrict=type(fx.wazaEntry)=="table",positionType=fx.wazaEntry and fx.wazaEntry.positionType,
flags=fx.wazaEntry and fx.wazaEntry.flags,particleEntry=fx.wazaEntry})
end
if not geometry then return false end
originSide=geometry.originSide or originSide
local liveSource,actor=geometry.origin,geometry.actor
local liveTarget,targetActor=geometry.target,geometry.targetActor






if not fx.basisLocked then
local right,up,forward=geometry.right,geometry.up,geometry.forward
if not right then right,up,forward=effectBasis(liveSource,liveTarget)end
fx.sourceWorld={liveSource[1],liveSource[2],liveSource[3]}
fx.targetWorld={liveTarget[1],liveTarget[2],liveTarget[3]}
fx.right=right;fx.up=up;fx.forward=forward;fx.basisLocked=true
if geometry.aimed or geometry.fieldWave or geometry.modelLinked then fx.aimUnits={x=geometry.sourceUnits.x,y=geometry.sourceUnits.y,z=geometry.sourceUnits.z}end
end
local source,target=fx.sourceWorld,fx.targetWorld
local right,up,forward=fx.right,fx.up,fx.forward
fx.originSide=originSide;fx.otherSide=otherSide;fx.originActor=actor;fx.targetActor=targetActor
fx.spatialStyle=geometry.style;fx.groundField=geometry.groundField
fx.sourceVisualHeight=geometry.sourceVisualHeight;fx.targetVisualHeight=geometry.targetVisualHeight
fx.referenceVisualHeight=geometry.referenceVisualHeight;fx.fightDistance=geometry.fightDistance





if fx.aimUnits then geometry.sourceUnits=fx.aimUnits end
fx.sourceUnits=geometry.sourceUnits
fx.sourceUnitsFromOwner=geometry.sourceUnitsFromOwner
fx.sourceUnit=(geometry.sourceUnits.x+geometry.sourceUnits.y+geometry.sourceUnits.z)/3



if fx.vm and not fx.modelLinked then
local joints={}
local ux=math.max(1e-6,geometry.sourceUnits.x)
local uy=math.max(1e-6,geometry.sourceUnits.y)
local uz=math.max(1e-6,geometry.sourceUnits.z)
for slot,name in ipairs(BODY_SLOT_NAMES) do
local wp=not fx.releaseGeometry and actorAttachmentWorld(originSide,name)
if wp then
local lp=worldToLocal(source,right,up,forward,wp)
joints[slot-1]={lp[1]/ux,lp[2]/uy,lp[3]/uz}
end
end
if fx.releaseGeometry then for i=0,11 do joints[i]={0,0,0} end end
fx.vm.joints=joints
if rootSlot and rootSlot>=0 and rootSlot<#BODY_SLOT_NAMES then
local lp=worldToLocal(source,right,up,forward,liveSource)
fx.vm.emissionOrigin={lp[1]/ux,lp[2]/uy,lp[3]/uz}
else fx.vm.emissionOrigin=nil end
end
return true
end

local function entryScale(entry)





return 1
end

local function particleImage(fx,p)
if not (fx and p) or p.textureOff then return nil end
local bank=tonumber(p.bank) or 1
local container=tonumber(p.animIndex) or 0
local texture=tonumber(p.textureIndex) or 0
if fx.indexedBanks and fx.indexedBanks[bank] then
local containers=fx.imagesByBankContainerIndex and fx.imagesByBankContainerIndex[bank]
return containers and containers[container] and containers[container][texture] or nil
end
local byContainer=fx.imagesByBankContainer and fx.imagesByBankContainer[bank]
local list=byContainer and byContainer[container] or nil

if not (list and #list>0) then list=fx.imagesByBank and fx.imagesByBank[bank] end
if not (list and #list>0) then return nil end
local idx=texture+1
if idx<1 then idx=1 end
return list[idx] or list[1]
end

local function particleColors(p)



local c=p and (p.primDisplay or p.prim) or {255,255,255,255}
local e=p and (p.envDisplay or p.env) or {0,0,0,0}
local function f(v,d)return math.max(0,math.min(1,(tonumber(v) or d)/255)) end
return {f(c[1],255),f(c[2],255),f(c[3],255),f(c[4],255)},
{f(e[1],0),f(e[2],0),f(e[3],0),f(e[4],0)}
end
local function particleAlphaCompare(p)
local a=p and p.alphaCompare
if MoveFXVM and MoveFXVM._test and type(MoveFXVM._test.alphaCompareCurrent)=="function" then
local mode,p1,p2=MoveFXVM._test.alphaCompareCurrent(p)
return mode,(tonumber(p1) or 1)/255,(tonumber(p2) or 255)/255
end
return tonumber(a and a.mode) or 0x33,(tonumber(a and a.p1) or 1)/255,(tonumber(a and a.p2) or 255)/255
end
local function sendParticleAlphaCompare(shader,p)
local mode,p1,p2=particleAlphaCompare(p)
shader:send("cbeAlphaMode",mode);shader:send("cbeAlphaP1",p1);shader:send("cbeAlphaP2",p2)
end

local function blendForParticle(g,p)
local mode=tonumber(p and p.blendMode) or 0
local ok
if mode==1 then ok=pcall(g.setBlendMode,"add","alphamultiply")
elseif mode==2 then ok=pcall(g.setBlendMode,"subtract","alphamultiply")
elseif mode==3 then ok=pcall(g.setBlendMode,"multiply","premultiplied")
else ok=pcall(g.setBlendMode,"alpha","alphamultiply") end


if not ok then pcall(g.setBlendMode,"alpha","alphamultiply") end
return ok
end

local function particleWorld(fx,p,pos)
if not (fx and fx.sourceWorld and fx.right and fx.up and fx.forward) then return nil end
local origin=fx.sourceWorld




if p and p.attachmentMatrix then
local a=p.attachmentMatrix;local q=pos or p.position
pos={a[1]*q[1]+a[2]*q[2]+a[3]*q[3]+a[4],
a[5]*q[1]+a[6]*q[2]+a[7]*q[3]+a[8],a[9]*q[1]+a[10]*q[2]+a[11]*q[3]+a[12]}
end
return localToWorld(origin,fx.right,fx.up,fx.forward,pos or (p and p.position),fx.sourceUnits or fx.sourceUnit)
end

local function particlePixelUnit(context,fx,actor,world)
local rs=context.services and context.services.renderSize
local fallback=18*((rs and rs.height) or 768)/768
if not world then return fallback end
if fx and (fx.modelLinked or fx.sourceUnitsFromOwner) then
local unit=math.max(1e-6,tonumber(fx.sourceUnits and fx.sourceUnits.y) or fx.sourceUnit or 1)
local x1,y1=projectMoveFxWorld(context,world)
local x2,y2=projectMoveFxWorld(context,{world[1],world[2]+unit,world[3]})
if x1 and x2 then return math.max(.1,math.sqrt((x2-x1)^2+(y2-y1)^2)) end
end
local localHeight=tonumber(fx and fx.referenceVisualHeight) or actorVisualHeight(actor)
if localHeight<=0 then return fallback end
local x1,y1=projectMoveFxWorld(context,world)
local x2,y2=projectMoveFxWorld(context,{world[1],world[2]+localHeight,world[3]})
if not (x1 and x2) then return fallback end
local apparent=math.sqrt((x2-x1)^2+(y2-y1)^2)






return math.max(3,math.min(72,apparent*.16))
end

local particleFilterState=setmetatable({},{__mode="k"})
local function drawParticleAt(g,shader,context,fx,p,entry,pos,trailAlpha)
local world=particleWorld(fx,p,pos);if not world then return false end
local x,y=projectMoveFxWorld(context,world);if not x then return false end
local img=entry.image;local iw,ih=img:getDimensions()
local sourceSize=math.abs(tonumber(p.size) or 1)




local particlePixels=particlePixelUnit(context,fx,fx.originActor,world)
local visible=math.max(1,math.min(320,sourceSize*particlePixels*entryScale(entry)))
local sc=visible/math.max(iw,ih)
if sc<=0 then return false end
local prim,env=particleColors(p)
local alpha=prim[4]*(trailAlpha or 1)



local visibleAlpha=(shader and p.primEnv) and math.max(alpha,env[4]*(trailAlpha or 1)) or alpha
if visibleAlpha<=0.002 then return false end
if shader then
shader:send("cbePrim",{prim[1],prim[2],prim[3],alpha})
shader:send("cbeEnv",{env[1],env[2],env[3],env[4]*(trailAlpha or 1)})
shader:send("cbePrimEnv",p.primEnv and 1 or 0)
shader:send("cbeIntensityAlpha",particleIntensityAlpha(entry.spec))
sendParticleAlphaCompare(shader,p)
g.setColor(1,1,1,1)
else g.setColor(prim[1],prim[2],prim[3],alpha) end
if type(img.setFilter)=="function" and particleFilterState[img]~=(p.nearest==true) then
local filt=p.nearest and "nearest" or "linear"
local aniso=p.nearest and 1 or 8
local ok=pcall(img.setFilter,img,filt,filt,aniso)
if not ok then ok=pcall(img.setFilter,img,filt,filt,1) end
if ok then particleFilterState[img]=(p.nearest==true) end
end
local angle=tonumber(p.rotation) or 0
if p.dirVec then
local vel=p.velocity or {0,0,0}
local wp2=localToWorld(world,fx.right,fx.up,fx.forward,vel,fx.sourceUnits or fx.sourceUnit)
local x2,y2=projectMoveFxWorld(context,wp2)
if x2 then angle=math.atan2 and math.atan2(y2-y,x2-x) or angle end
end


local sx=(p.flipS and -sc or sc);local sy=(p.flipT and -sc or sc)
blendForParticle(g,p)
g.draw(img,x,y,angle,sx,sy,iw*.5,ih*.5)
return true
end

local TRAIL_MESH_FORMAT={{"VertexPosition","float",2},{"VertexTexCoord","float",2},{"VertexColor","float",4}}
local particleTrailMesh
local function drawTrailRibbon(g,shader,context,fx,p,entry)
if not (p and p.trail and entry and entry.image and p.position and p.velocity) then return false end



local prev={p.position[1]-(p.velocity[1] or 0),p.position[2]-(p.velocity[2] or 0),p.position[3]-(p.velocity[3] or 0)}
local oldWorld=particleWorld(fx,p,prev);local liveWorld=particleWorld(fx,p,p.position)
if not (oldWorld and liveWorld) then return false end
local x0,y0=projectMoveFxWorld(context,oldWorld);local x1,y1=projectMoveFxWorld(context,liveWorld)
if not (x0 and x1) then return false end
local dx,dy=x1-x0,y1-y0;local len=math.sqrt(dx*dx+dy*dy)
if len<1e-5 then return false end
local nx,ny=-dy/len,dx/len
local sourceSize=math.max(.20,math.abs(tonumber(p.size) or 1))
local point=math.floor((tonumber(p.flags) or 0)/0x40000000)%2==1
local width
if point then width=math.max(1,math.min(255,6*sourceSize))
else width=math.max(1,math.min(320,particlePixelUnit(context,fx,fx.originActor,liveWorld)*sourceSize)) end
local hw=width*.5
local tailAlpha=math.max(0,math.min(1,tonumber(p.trailAlpha) or 1))
local verts={
{x0+nx*hw,y0+ny*hw,0,0,1,1,1,tailAlpha},
{x0-nx*hw,y0-ny*hw,0,1,1,1,1,tailAlpha},
{x1+nx*hw,y1+ny*hw,1,0,1,1,1,1},
{x1-nx*hw,y1-ny*hw,1,1,1,1,1,1},
}

local mesh=particleTrailMesh
if not mesh then
local ok,m=pcall(love.graphics.newMesh,TRAIL_MESH_FORMAT,4,"strip","stream")
if not ok or not m then return false end
mesh=m;particleTrailMesh=mesh
end
if not pcall(mesh.setVertices,mesh,verts) then return false end
if mesh.setDrawRange then mesh:setDrawRange(1,4) end
pcall(mesh.setTexture,mesh,entry.image)
local prim,env=particleColors(p)
if shader then
g.setShader(shader)
shader:send("cbePrim",prim);shader:send("cbeEnv",env)
shader:send("cbePrimEnv",p.primEnv and 1 or 0)
shader:send("cbeIntensityAlpha",particleIntensityAlpha(entry.spec))
sendParticleAlphaCompare(shader,p)
end
blendForParticle(g,p)
g.setColor(1,1,1,1)
g.draw(mesh)
return true
end






local function graphicsScope(g,fn)
local pushed=false
local okPush,pushErr=pcall(g.push,"all")
if not okPush then return false,nil,pushErr end
pushed=true
local ok,value=pcall(fn)


pcall(g.setShader)
pcall(g.setDepthMode)
if pushed then pcall(g.pop) end
if not ok then return false,nil,value end
return true,value,nil
end

local function recordMoveFxRenderFault(fx,p,err)
local moveId=fx and (fx.moveId or (fx.spec and fx.spec.moveId)) or "?"
local msg=("MoveFX render fault move=%s: %s"):format(tostring(moveId),tostring(err))
P.moveFxError=msg
P.moveFxRenderFaults=(tonumber(P.moveFxRenderFaults) or 0)+1
if type(p)=="table" then
p._cbeRenderFaults=(tonumber(p._cbeRenderFaults) or 0)+1



if p._cbeRenderFaults>=3 then p._cbeRenderDisabled=true end
end
return msg
end

local function relinquishMoveFx(fx,context,reason)
if not (fx and tonumber(fx.moveId) and not fx.visualRelinquished) then return false end
local ownership=V.MoveFXOwnership
if not (ownership and type(ownership.relinquish)=="function") then return false end
local ok,released=pcall(ownership.relinquish,ownership,context or fx.context,fx.moveId,reason)
if ok and released==true then fx.visualRelinquished=true;return true end
return false
end

local function drawMoveFx(context)
local g=love and love.graphics
if not (g and MoveFXVM and #P.moveFxActive>0) then return false end
local drew=false
local ok,value,err=graphicsScope(g,function()
g.setDepthMode()
local shader=moveFxShader()
if not shader then
local reason=P.moveFxError or "source GPT1 shader unavailable"
for _,fx in ipairs(P.moveFxActive) do relinquishMoveFx(fx,context,reason) end
return false
end
g.setShader(shader)
for _,fx in ipairs(P.moveFxActive) do
if not fx.visualRelinquished and refreshMoveFxBasis(context,fx) then
for _,p in ipairs(MoveFXVM.visibleParticles(fx.vm) or {}) do
if not p._cbeRenderDisabled then
local entry=particleImage(fx,p)
if not entry and not p.textureOff and fx.indexedBanks and fx.indexedBanks[tonumber(p.bank) or 1]
and not fx.missingTextureReported then
fx.missingTextureReported=true
local reason=("source GPT1 texture missing: bank=%s container=%s texture=%s"):format(
tostring(p.bank),tostring(p.animIndex),tostring(p.textureIndex))
P.moveFxError=reason
relinquishMoveFx(fx,context,reason)
end
if entry and p.alive~=false then
if p.trail then
local okTrail,didTrail=pcall(drawTrailRibbon,g,shader,context,fx,p,entry)
if okTrail then drew=didTrail or drew
else
local reason=recordMoveFxRenderFault(fx,p,didTrail)
if p._cbeRenderDisabled then relinquishMoveFx(fx,context,reason) end
pcall(g.setShader,shader)
end
else
local okParticle,didParticle=pcall(drawParticleAt,g,shader,context,fx,p,entry,p.position,1)
if okParticle then drew=didParticle or drew
else
local reason=recordMoveFxRenderFault(fx,p,didParticle)
if p._cbeRenderDisabled then relinquishMoveFx(fx,context,reason) end
pcall(g.setShader,shader)
end
end
end
end
end
end
end
return drew
end)
if not ok then
local reason=recordMoveFxRenderFault(nil,nil,err)
for _,fx in ipairs(P.moveFxActive) do relinquishMoveFx(fx,context,reason) end
return false
end
return value==true
end

local function targetGeometry(context,side)
local x,z=anchor(context,side); if not x then return nil end
local arena=context.arena or {}
local k=math.max(.08,tonumber(arena.figureScale) or .38)
local px,py=project(context,x,0,z); if not px then return nil end




local physicalH=side=="player" and 24.5 or 25.5
local tx,ty=project(context,x,physicalH/k,z)
local targetH=ty and math.abs(py-ty) or nil
if not targetH or targetH<8 then
local rs=context.services and context.services.renderSize
targetH=((rs and rs.height) or 768)*.115
end
targetH=math.max(34,math.min(targetH,190))
return px,py,targetH
end

local function playerFlip()
local runtime=battleArtRuntime()
local art=runtime and runtime.art
if not art then return false end
local side=type(art.playerSide)=="function" and art.playerSide() or "back"
if side~="front" then return false end
if type(art.flipsPlayerFront)=="function" then
local ok,value=pcall(art.flipsPlayerFront)
return ok and value==true
end
return false
end

local function drawStadiumActors(context)
if P.mode~="stadium" then return false end
local api=P.actorApi or stadiumService()
local services=context and context.services
local vp=services and ((api and api.worldUnits==true and services.stageVP) or services.vp)
local arena=context and context.arena
if not (api and type(vp)=="table" and arena) then return false end
local jobs={}
local renderFault
local function fault(why)
renderFault=tostring(why or "Colosseum actor render failed")
if P.modeId=="cbe:colosseum-pokemon" and V.BattleCache then
V.BattleCache.noteRenderError(context.game,renderFault)
end
end




for _,record in ipairs(P.retiringActors) do
local side=record.side
local actor=record.actor
local cell=side and arena[side]
local other=side and arena[side=="player" and "enemy" or "player"]
if actor and type(cell)=="table" and type(other)=="table"
and type(actor.matrix)=="function" and type(actor.draw)=="function" then
driveRetiringActor(context,record)
local ok,matrix=pcall(actor.matrix,actor,cell[1],context.groundY or 0,cell[2],
(other[1] or 0)-(cell[1] or 0),(other[2] or 0)-(cell[2] or 0))
if ok and matrix then jobs[#jobs+1]={side=side,actor=actor,matrix=matrix,retiring=true} end
end
end

for _,side in ipairs(SIDES_EP) do
local existing=P.stadiumActors[side] and P.stadiumActors[side].actor
local actor=actorVisible(context,side,existing) and stadiumActor(context,side) or nil
local cell=arena[side]
local other=arena[side=="player" and "enemy" or "player"]
if actor and type(cell)=="table" and type(other)=="table"
and type(actor.matrix)=="function" and type(actor.draw)=="function" then
driveSpawn(context,side,actor)
local ok,matrix=pcall(actor.matrix,actor,cell[1],context.groundY or 0,cell[2],
(other[1] or 0)-(cell[1] or 0),(other[2] or 0)-(cell[2] or 0))
if ok and matrix then jobs[#jobs+1]={side=side,actor=actor,matrix=matrix} else fault(matrix or "Colosseum matrix unavailable") end
end
end
if #jobs==0 then return false end
local any=false
local ok,accepted,err=pcall(api.withRenderer,vp,function()
for _,job in ipairs(jobs) do
local built=true
if type(job.actor.build)=="function" then
local okBuild,value=pcall(job.actor.build,job.actor)
built=okBuild and value~=false
if not built then fault(value or "Colosseum actor build failed") end
end
if built then
local okDraw,value=pcall(job.actor.draw,job.actor,job.matrix,0)
if okDraw and value~=false then
P.drawn[job.side]=true;P.presented[job.side]=true;any=true
else
fault(value or "Colosseum actor draw failed")
end
end
end
return true
end,{
eye=services and services.camera and services.camera.pose and services.camera.pose.eye,
focus=services and services.camera and services.camera.pose and services.camera.pose.focus,
width=services and services.renderSize and services.renderSize.width,
height=services and services.renderSize and services.renderSize.height,
context=context,
})
if not ok or accepted==false then
P.stadiumError=tostring(ok and err or accepted)
if P.modeId=="cbe:colosseum-pokemon" and V.BattleCache then V.BattleCache.noteRenderError(context.game,P.stadiumError) end
return false
end
P.stadiumError=renderFault
return any
end

function P:available(context)
return arenasEnabled(context) and ourArena(context)
end

function P:begin(context)
self.drawn.player=false;self.drawn.enemy=false
self.presented.player=false;self.presented.enemy=false
self.moveFxActive={};self.moveFxError=nil;self.moveFxRenderFaults=0
if self.moveFxShader==false then self.moveFxShader=nil end
installWazaHandlers()
if WazaSequence and type(WazaSequence.finish)=="function" then pcall(WazaSequence.finish,WazaSequence,context,"battle-begin-reset") end
battleArtRuntime()
stadiumService()
selectPresentation(context,true)
local available=self:available(context)






return available
end

local function actorDelta(context,dt)
return math.max(0,tonumber(dt) or 0)
end

local function recordMon(record)
local battler=record and record.battler
return battler and (battler.mon or battler.pokemon) or battler
end

local function beginPendingFaintReturn(context,side,record)
if not (record and record.faintReturnPending) or P.faintReturns[side] then return false,"not-pending" end
local actor=record.actor



if actor and actor.state~="faint" then return false,"waiting-for-faint-state" end
local RP=V and V.ReleasePresentation
if not (RP and type(RP.beginFaintSingle)=="function") then return false,"runtime-unavailable" end
if actor and type(RP.faintStartDelayFor)=="function" then
local okDelay,delay=pcall(RP.faintStartDelayFor,recordMon(record),actor)
delay=okDelay and math.max(0,tonumber(delay) or 0) or 0
if (tonumber(actor.faintAge) or 0)+1e-6<delay then return false,"waiting-for-faint-overlap" end
end
record.faintReturnPending=nil
local okReturn,sourceReturn,why=pcall(RP.beginFaintSingle,context,side,recordMon(record),actor)
if okReturn and sourceReturn then P.faintReturns[side]=sourceReturn;return true,sourceReturn end
if actor then actor.cbeSourceFaintReturn=nil end
P.moveFxError="source faint-return unavailable: "..tostring(okReturn and why or sourceReturn)
return false,"source-unavailable"
end

function P:update(context,dt)
if V.DoublesRuntime and (V.DoublesRuntime.presentation or V.DoublesRuntime.combat)(context and context.battle) then return end



liveBattler(context,"player")
liveBattler(context,"enemy")
selectPresentation(context,false)
directedMoveFx(context)
updateMoveFx(context,dt)




battleArtRuntime()
syncBattleArtSpecies(context,dt,true)
if P.mode=="external" then
local ok=invokeExternal(context,"update",dt or 0)
if not ok then
finishExternal(context,"update-failed")
P.mode="sprites";P.modeId="builtin:resolved-sprites"
end
elseif P.mode=="stadium" then
local actorDt=actorDelta(context,dt)
local RP=V and V.ReleasePresentation




for _,side in ipairs(SIDES_PE) do
local sourceReturn=P.faintReturns and P.faintReturns[side]
if sourceReturn and RP and type(RP.updateFaintSingle)=="function" then
local okReturn,advanced=pcall(RP.updateFaintSingle,context,sourceReturn,actorDt)
if not okReturn or advanced==false then
P.moveFxError="source faint-return runtime failed closed: "..tostring(okReturn and sourceReturn.error or advanced)
if type(RP.finishFaint)=="function" then pcall(RP.finishFaint,sourceReturn,context,nil,"source-runtime-failed") end
P.faintReturns[side]=nil
end
end
end


for i=#P.retiringActors,1,-1 do
local record=P.retiringActors[i]
local actor=record and record.actor
driveRetiringActor(context,record)
if actor and type(actor.update)=="function" then pcall(actor.update,actor,actorDt) end
local done=false
if actor and type(actor.terminalComplete)=="function" then
local ok,value=pcall(actor.terminalComplete,actor)
done=ok and value==true
elseif actor and actor.state=="removal" then
done=true
end
if done then
table.remove(P.retiringActors,i)
releaseActorRecord(record,record.retireReason or "tail-complete")
end
end

for _,side in ipairs(SIDES_PE) do
syncStadiumActor(context,side)
local existing=P.stadiumActors[side] and P.stadiumActors[side].actor
local actor=existing or (actorVisible(context,side,existing) and stadiumActor(context,side) or nil)
driveSpawn(context,side,actor)
local TP=V and V.TrainerPerformance
local actorStep=TP and TP.pokemonDt and TP.pokemonDt(context,actorDt,actor) or actorDt
local WH=V and V.WazaHandlers
if WH and type(WH.actorControllerState)=="function" and not (actor and (actor.state=="faint" or actor.pendingFaint)) then
local okController,controller=pcall(WH.actorControllerState,WH,side)
if okController and type(controller)=="table" and controller.motionFrozen==true then actorStep=0 end
end



if actor and type(actor.update)=="function" then pcall(actor.update,actor,actorStep) end
if P.stadiumActors[side] and P.stadiumActors[side].faintReturnPending then
beginPendingFaintReturn(context,side,P.stadiumActors[side])
end
end
end
end

local function hasRetiringActor(side)
for _,record in ipairs(P.retiringActors) do
if record and record.side==side and record.actor then return true end
end
return false
end

function P:covers(context,side)
if not self:available(context) then return false end




if doublesOpeningPending(context) then return true end











local doublesRuntime=V and V.DoublesRuntime
if doublesRuntime then
local lookup=type(doublesRuntime.presentation)=='function' and doublesRuntime.presentation
or (type(doublesRuntime.combat)=='function' and doublesRuntime.combat or nil)
if lookup then
local ok,session=pcall(lookup,context and context.battle)
if ok and session then return true end
end
end
if self.mode=="native" then return false end






if self.mode=="stadium" and self.modeId=="cbe:colosseum-pokemon"
and cbePokemonModelsEnabled(context) then
local b=liveBattler(context,side)
if b then return true end
end






if self.mode=="stadium" then
if hasRetiringActor(side) then return true end
local actor=P.stadiumActors[side] and P.stadiumActors[side].actor
local b=liveBattler(context,side)
local absent=b and (b.invulnerable==true or (b.mon and b.mon.volatile or {}).vanished==true)
if actor and (absent or actorVisible(context,side,actor)) then return true end
elseif self.drawn[side]==true and visible(context,side) then
return true
end







local b=liveBattler(context,side)
return self.presented[side]==true and b~=nil and b.fainted==true
end

function P:cameraLocked() return false end

function P:drawWorld(context)
local doubles=V.DoublesRuntime and (V.DoublesRuntime.presentation or V.DoublesRuntime.combat)(context and context.battle)
if doubles then return V.DoublesPresenter.draw(doubles,context) end
local g=love and love.graphics
if not (g and context) then return false end
self.drawn.player=false;self.drawn.enemy=false
if self.mode=="native" then return false end
local any=false
local externalValue=false
if self.mode=="external" then
local ok,value=invokeExternal(context,"drawWorld",0)
if ok then
for _,side in ipairs(SIDES_EP) do
local coveredOk,covered=invokeExternal(context,"covers",side)
self.drawn[side]=coveredOk and covered==true and visible(context,side)
if self.drawn[side] then self.presented[side]=true end
any=any or self.drawn[side]
end



externalValue=value==true
else
finishExternal(context,"draw-failed")
self.mode="sprites";self.modeId="builtin:resolved-sprites"
end
end
any=drawStadiumActors(context) or any
local oldFilterMin,oldFilterMag,oldAniso=g.getDefaultFilter()
g.setDefaultFilter("nearest","nearest",oldAniso or 1)
local spriteOk,_,spriteErr=graphicsScope(g,function()
g.setShader();g.setDepthMode();g.setColor(1,1,1,1)
for _,side in ipairs(SIDES_EP) do





local cbeAbsolute=self.mode=="stadium"
and self.modeId=="cbe:colosseum-pokemon"
and cbePokemonModelsEnabled(context)
local captureHidden=false
local captureScale=1
if side=="enemy" and PlayerTrainer then
if type(PlayerTrainer.captureEnemyScale)=="function" then
local okScale,value=pcall(PlayerTrainer.captureEnemyScale,PlayerTrainer,context)
if okScale and tonumber(value) then captureScale=math.max(0,math.min(1,tonumber(value))) end
end
if type(PlayerTrainer.captureHidesEnemy)=="function" then
local okHidden,value=pcall(PlayerTrainer.captureHidesEnemy,PlayerTrainer,context)
captureHidden=okHidden and value==true
end
end
local image=(not self.drawn[side] and not cbeAbsolute and not captureHidden)
and imageFor(context,side) or nil
local px,py,targetH=targetGeometry(context,side)
if image and px and py and targetH then
local w,h=image:getDimensions()
if w>0 and h>0 then
local s=targetH/h
local sx=s
if side=="player" and playerFlip() then sx=-s end
local b=liveBattler(context,side)
local faint=faintProgress(context,b)
local grow=growScale(context,b)
if faint~=nil then
local visibleH=math.max(0,math.floor(h*(1-faint)+.5))
if visibleH>0 then
if faintQuad and faintQuad.setViewport then
pcall(faintQuad.setViewport,faintQuad,0,0,w,visibleH,w,h)
else
faintQuad=g.newQuad(0,0,w,visibleH,w,h)
end
g.draw(image,faintQuad,px,py,0,sx,s,w*.5,visibleH)
self.drawn[side]=true;self.presented[side]=true; any=true
end
else



local presentScale=(grow~=nil and grow or 1)*captureScale
if presentScale>0 then
if presentScale<.999 then
local eff=s*presentScale
local ex=eff
if side=="player" and playerFlip() then ex=-eff end
g.draw(image,px,py,0,ex,eff,w*.5,h)
else
g.draw(image,px,py,0,sx,s,w*.5,h)
end
self.drawn[side]=true;self.presented[side]=true; any=true
end
end
end
end
end
return true
end)
if not spriteOk then self.spriteError="render: "..tostring(spriteErr) end
local wh=V and V.WazaHandlers
if wh and type(wh.drawWorld)=="function" then
local okW,drewW=pcall(wh.drawWorld,context)
if okW and drewW then any=true end
end
any=drawMoveFx(context) or any
local RP=V and V.ReleasePresentation
if RP and type(RP.drawFaintSingle)=="function" then
for _,side in ipairs(SIDES_PE) do
local sourceReturn=P.faintReturns and P.faintReturns[side]
if sourceReturn then
local okReturn,drewReturn=pcall(RP.drawFaintSingle,context,sourceReturn)
if okReturn and drewReturn then any=true end
end
end
end
g.setDefaultFilter(oldFilterMin,oldFilterMag,oldAniso or 1)
return any or externalValue
end

function P:center(context,side)
local x,z=anchor(context,side); if not x then return nil end
local arena=context.arena or {}; local k=math.max(.08,tonumber(arena.figureScale) or .38)
return project(context,x,14/k,z)
end
function P:screenCenter(context,side) return self:center(context,side) end
function P:showing(context,side) return self.drawn[side]==true end
function P:footprint() return 18 end



function P:faintPresentationBusy(context)
if self.mode~="stadium" then return false end
local RP=V and V.ReleasePresentation
for _,side in ipairs(SIDES_PE) do
local record=self.stadiumActors[side]
if record and record.faintReturnPending then return true end
local sourceReturn=self.faintReturns[side]
if sourceReturn and RP and type(RP.faintComplete)=="function" then
local ok,done=pcall(RP.faintComplete,sourceReturn)
if ok and done~=true then return true end
end
end
return false
end
function P:event(context,name,payload)



if type(payload)=="table" then
if seenEventPayload[payload]==name then return end
seenEventPayload[payload]=name
end
if P.mode=="external" then
local ok=invokeExternal(context,"event",name,payload)
if ok then return end
finishExternal(context,"event-failed")
P.mode="sprites";P.modeId="builtin:resolved-sprites"
end
local S=V.BattleSides
local side
local gen2=context and context.battle and context.battle.__cbeGeneration==2
local gen3Owned=context and context.battle and context.battle.__cbeGeneration==3
and V.Gen3Presentation and V.Gen3Presentation.session
and V.Gen3Presentation.session.screen==context.battle
local queueSync=context and context.battle and context.battle.__cbePresentationQueueSync==true



if queueSync and ((gen2 or gen3Owned) and
(name=="battle.move_used" or name=="battle.damage_dealt" or name=="battle.fainted")) then return end
if queueSync and name=="battle.fainted" then return end
local semantic=name
if name=="battle.presentation_damage" then semantic="battle.damage_dealt"
elseif name=="battle.presentation_faint" then semantic="battle.fainted" end
if semantic=="battle.move_used" or name=="battle.presentation_move" then
side=(S and S.payload and S.payload(context,payload,{"user","side"})) or (payload and payload.side)
local actor=nil
if side and P.mode=="stadium" then
local resident=P.stadiumActors[side]
actor=resident and resident.actor or stadiumActor(context,side)
end
local move=payload and payload.move
local moveId=(move and (move.index or move.id)) or (payload and payload.moveId)
local game=context and context.game
if type(move)~="table" and game and game.data and game.data.moves then
move=game.data.moves[moveId]
end
if type(moveId)~="number" then
local order=game and game.data and game.data.gen2Constants
and game.data.gen2Constants.moveOrder
if type(order)=="table" then
for i,id in ipairs(order) do if id==moveId then moveId=i;break end end
end
end
local resolvedId=moveId~=nil and (tonumber(moveId) or moveId) or nil
if actor then
local key=tonumber(resolvedId) or tostring(resolvedId or ""):lower():gsub("[^a-z0-9]","")
actor.cbeStructuralDeparture=STRUCTURAL_HIDE_MOVE[key] and (not payload or payload.charging~=false) or nil
end
local spec
if resolvedId~=nil and MoveFX then
if type(MoveFX.peek)=="function" then
local okPeek,value=pcall(MoveFX.peek,resolvedId,move)
if okPeek and type(value)=="table" then spec=value end
end




if not spec and type(MoveFX.queuePrefetch)=="function" then
pcall(MoveFX.queuePrefetch,resolvedId,move,context and context.battle)
P.moveFxError="source MoveFX cache queued; first uncached use failed open without blocking"
end
end

if spec and V.WazaPhasePolicy then
spec=V.WazaPhasePolicy.select(spec,{moveId=tonumber(resolvedId),dex=actor and actor.dex,
stage=payload and payload.charging==true and "charge" or "attack"})
end

local function bindStartedAttack(activeActor,nativeSampled)
local function releaseFailedVisual(reason)
local ownership=V and V.MoveFXOwnership
if ownership and type(ownership.relinquish)=="function" then
pcall(ownership.relinquish,ownership,context,resolvedId,reason)
end
end



if P.mode=="stadium" and (not activeActor or not activeActor.nativeSlot) then
P.moveFxError="source Pokemon attack timing row unavailable; Waza attack timeline withheld"
releaseFailedVisual(P.moveFxError)
return false
end
local attackDuration,wazaTimingPoints,presentationFrames,animationSlot,animationName
if activeActor then
if type(activeActor.stateDuration)=="function" then
local okDur,value=pcall(activeActor.stateDuration,activeActor,"attack")
if okDur then attackDuration=tonumber(value) end
end
wazaTimingPoints=actorWazaTiming(activeActor)
presentationFrames=attackDuration and math.floor(math.max(0,attackDuration)*60+.5) or nil
animationSlot=activeActor.nativeSlot and activeActor.nativeSlot.index or activeActor.nativeClip
animationName=activeActor.nativeActionName or activeActor.requestedNativeSlot
end
local directorSeq
if Director and type(Director.bindAttack)=="function" and resolvedId~=nil then
local okBind,bound=pcall(Director.bindAttack,Director,context,side,resolvedId,move,attackDuration,spec,
wazaTimingPoints,presentationFrames,animationSlot,animationName)
if okBind and type(bound)=="table" then directorSeq=bound
elseif not okBind then P.moveFxError="BattleDirector attack bind failed: "..tostring(bound) end
if not spec and MoveFX and type(MoveFX.mapped)=="function" then
local okMap,mapped=pcall(MoveFX.mapped,resolvedId,move)
if okMap and mapped then P.moveFxError="mapped source FX was not prefetched before move playback" end
end
end
if spec then
local hasAttackTimeline=roleHasTimeline(spec,"attack")
if hasAttackTimeline and not (directorSeq and directorSeq.wazaAttackSerial) then
local started=startWazaSequence(context,side,spec,nil,"attack",resolvedId,move)
if not started then
P.moveFxError=P.moveFxError or "source attack Waza timeline could not start"
releaseFailedVisual(P.moveFxError)
end
end
if not hasAttackTimeline and roleHasSource(spec,"attack") then
if not stageMoveFx(context,side,spec,nil,"attack") and not P.moveFxError then
P.moveFxError="verified source attack MoveFX could not be staged"
end
if P.moveFxError then releaseFailedVisual(P.moveFxError) end
elseif not hasAttackTimeline and roleHasSource(spec,"damage") then
P.moveFxError=nil
end




local selectedReceiving=spec.phaseSelection and spec.phaseSelection.damage
local power=tonumber(type(move)=="table" and move.power)
local category=type(move)=="table" and tostring(move.category or ""):lower() or ""
if selectedReceiving and (not hasAttackTimeline or (power and power<=0) or category=="status")
and not (payload and (payload.missed==true or payload.charging==true)) then
local targetSide=(S and S.payload and S.payload(context,payload,{"target"}))
or (type(payload and payload.target)=="string" and payload.target)
if not targetSide then
local targetKind=type(move)=="table" and tostring(move.target or ""):lower() or ""
targetSide=(spec.style=="self" or targetKind=="self" or targetKind=="user") and side
or (side=="player" and "enemy" or "player")
end
local started=false
if roleHasTimeline(spec,"damage") and Director and type(Director.bindDamage)=="function" then
local okStatus,inst=pcall(Director.bindDamage,Director,context,side,targetSide,spec,resolvedId,move,nil,0)
started=okStatus and type(inst)=="table"
elseif roleHasSource(spec,"damage") then
started=stageMoveFx(context,side,spec,targetSide,"damage")
end
if not started then
P.moveFxError=P.moveFxError or "source status Waza could not start at move boundary"
releaseFailedVisual(P.moveFxError)
end
end
elseif resolvedId~=nil then
startMoveFx(context,side,resolvedId,move,"attack")
end
return true
end

if P.mode=="stadium" then
if actor and type(actor.attack)=="function" and resolvedId~=nil then
local sourceSlot,sourceSequenceKind=sourceNativeSlot(spec,"attack")
local okAttack,accepted,attackState=pcall(actor.attack,actor,resolvedId,move,{
sourceWaza=type(spec)=="table" and roleHasTimeline(spec,"attack"),
nativeSlot=sourceSlot,
sourceSequenceKind=sourceSequenceKind,
onStarted=bindStartedAttack,
})
if not okAttack or accepted==false then
P.moveFxError="source Pokemon attack dispatch failed: "..tostring(okAttack and attackState or accepted)
local ownership=V and V.MoveFXOwnership
if ownership and type(ownership.relinquish)=="function" then
pcall(ownership.relinquish,ownership,context,resolvedId,P.moveFxError)
end
elseif attackState=="queued" then

P.moveFxError=nil
end
elseif resolvedId~=nil then
P.moveFxError="resident Colosseum Pokemon actor unavailable at move boundary; source attack withheld"
end
else

bindStartedAttack(nil,true)
end
elseif semantic=="battle.damage_dealt" then
side=(S and S.payload and S.payload(context,payload,{"target","side"})) or (payload and payload.side)



local actor=side and P.stadiumActors[side] and P.stadiumActors[side].actor or nil
if not actor and side then actor=stadiumActor(context,side) end





local attacker=side=="player" and "enemy" or (side=="enemy" and "player" or nil)
local damageSeq
if attacker and Director and type(Director.move)=="function" then
local okSeq,seq=pcall(Director.move,Director,context,attacker)
if okSeq and type(seq)=="table" and type(seq.fxSpec)=="table" then damageSeq=seq end
end
local damageSpec=damageSeq and damageSeq.fxSpec
if damageSpec and V.WazaPhasePolicy then damageSpec=V.WazaPhasePolicy.select(damageSpec) end
local damageSlot,damageSequenceKind
if damageSpec then damageSlot,damageSequenceKind=sourceNativeSlot(damageSpec,"damage") end
local function bindStartedDamage(activeActor,nativeSampled)




if damageSeq then
local seq=damageSeq
local points=actorWazaTiming(activeActor)
local damageFrames
if activeActor and type(activeActor.stateDuration)=="function" then
local okDur,dur=pcall(activeActor.stateDuration,activeActor,"hit")
if okDur and tonumber(dur) then damageFrames=math.floor(math.max(0,tonumber(dur))*60+.5) end
end
local hasDamageTimeline=roleHasTimeline(damageSpec,"damage")
local bound=false
local zeroPower=type(seq.move)=="table" and tonumber(seq.move.power)
if hasDamageTimeline and seq.wazaDamageSerial and
((damageSpec.phaseSelection and damageSpec.phaseSelection.damage=="status")
or (zeroPower and zeroPower<=0)) then
bound=true
elseif hasDamageTimeline and Director and type(Director.bindDamage)=="function" then
local okBind,inst=pcall(Director.bindDamage,Director,context,attacker,side,damageSpec,seq.moveId,seq.move,points,damageFrames)
bound=okBind and type(inst)=="table"
elseif hasDamageTimeline then
bound=startWazaSequence(context,attacker,damageSpec,side,"damage",seq.moveId,seq.move)
end
if not hasDamageTimeline and roleHasSource(damageSpec,"damage") then


stageMoveFx(context,attacker,damageSpec,side,"damage")
elseif hasDamageTimeline and not bound then
P.moveFxError=P.moveFxError or "source damage Waza timeline could not start"
end
end
return true
end
if actor and type(actor.hit)=="function" then
pcall(actor.hit,actor,payload,{nativeSlot=damageSlot,
sourceSequenceKind=damageSequenceKind,onStarted=bindStartedDamage})
else bindStartedDamage(nil,true) end
elseif semantic=="battle.fainted" then
side=(S and S.payload and S.payload(context,payload,{"battler","side"})) or (payload and payload.side)
local record=side and P.stadiumActors[side]
local actor=record and record.actor
if actor and type(actor.faint)=="function" then



pcall(actor.faint,actor,"collapse")
local RP=V and V.ReleasePresentation
record.faintReturnPending=true
beginPendingFaintReturn(context,side,record)
if Director and type(Director.bindFaint)=="function" then
local duration
if type(actor.terminalDuration)=="function" then
local okDur,value=pcall(actor.terminalDuration,actor,"faint");if okDur then duration=tonumber(value) end
elseif type(actor.stateDuration)=="function" then
local okDur,value=pcall(actor.stateDuration,actor,"faint");if okDur then duration=tonumber(value) end
end
local sourceDuration
if RP and type(RP.faintDurationFor)=="function" then
local okSource,value=pcall(RP.faintDurationFor,recordMon(record),actor);if okSource then sourceDuration=tonumber(value) end
end
if sourceDuration then
local wait=0
if actor.hitAge and type(actor.stateDuration)=="function" then
local okHit,hitDuration=pcall(actor.stateDuration,actor,"hit")
if okHit and tonumber(hitDuration) then wait=math.max(0,tonumber(hitDuration)-tonumber(actor.hitAge or 0)) end
end
local sourceDelay=0
if RP and type(RP.faintStartDelayFor)=="function" then
local okDelay,value=pcall(RP.faintStartDelayFor,recordMon(record),actor)
if okDelay then sourceDelay=math.max(0,tonumber(value) or 0) end
end
duration=wait+math.max(tonumber(duration) or 0,sourceDelay+sourceDuration)
end
pcall(Director.bindFaint,Director,context,side,duration)
end
end
elseif name=="battle.battler_switched" then
side=(S and S.payload and S.payload(context,payload,
{"battler","replacement","target","side","oldBattler","newBattler"}))
or (payload and S and S.value and S.value(payload.side))
if side then
local record=P.stadiumActors[side]
local live=liveBattler(context,side)
local previous=payload and (payload.previous or payload.oldBattler)




if record and ((previous and record.battler==previous) or record.battler~=live) then
retireStadiumActor(side,"switch-return")
end
else


syncStadiumActor(context,"player");syncStadiumActor(context,"enemy")
end
end
end
function P:finish(context,reason)
self.drawn.player=false;self.drawn.enemy=false
self.moveFxActive={}
local RP=V and V.ReleasePresentation
if RP and type(RP.finishFaint)=="function" then
for _,sourceReturn in pairs(self.faintReturns or {}) do pcall(RP.finishFaint,sourceReturn,context,nil,reason or "battle-ended") end
end
self.faintReturns={}
if P.animated and type(P.animated.finish)=="function"
and context and context.battle and not cbePokemonModelsEnabled(context) then
pcall(P.animated.finish,context.battle)
end
if WazaSequence and type(WazaSequence.finish)=="function" then pcall(WazaSequence.finish,WazaSequence,context,reason or "battle-ended") end
self.presented.player=false;self.presented.enemy=false
finishExternal(context,reason or "battle-ended")
releaseStadiumActors(reason or "battle-ended")
self.actorApi=nil;self.actorOwner=nil
self.spriteApi=nil;self.spriteOwner=nil;self.spriteError=nil
self.mode="sprites";self.modeId="builtin:resolved-sprites"
end
function P:invalidate(context)
if P.externalProvider then invokeExternal(context,"invalidate") end
self:finish(context,"invalidated")
end

local function restoreCbeWrapper(built,method,marker)
local original=rawget(built,marker)
if original==nil then return false end
built[method]=(original~=false) and original or nil
built[marker]=nil
return true
end

local function patchPreferred(stadium)
local built=stadium and stadium.exports and stadium.exports.modelProvider
if type(built)~="table" then return false end














restoreCbeWrapper(built,"update","__cbeOriginalUpdate")
restoreCbeWrapper(built,"begin","__cbeOriginalBegin")
restoreCbeWrapper(built,"finish","__cbeOriginalFinish")
restoreCbeWrapper(built,"covers","__cbeOriginalCovers")
restoreCbeWrapper(built,"preferredExternal","__cbeOriginalPreferredExternal")

built.__cbeStartupRecoveryVersion=nil
built.__cbeStartupRecoveryOwnerInstance=nil
built.__cbeStartupGrowRecoveryState=nil
built.__cbeActorPreferenceVersion=nil
built.__cbePreferenceOwnerInstance=nil










P.preferredPatched=true
return true
end

function P.register(stadium,api)
if P.registered then patchPreferred(stadium);return true end
api=api or (stadium and stadium.exports and stadium.exports.battles)
if not (api and api.version==1 and type(api.registerComponent)=="function") then return false end
local id=api:registerComponent(OWNER,"models","current-sprites",{
label="CURRENT SPRITES",
description="Use the Pokemon artwork already resolved by the user's active sprite/Battle Art pipeline inside Colosseum environments.",
provider=P,
available=function(context) return P:available(context) end,
})
P.id=id;P.registered=true
patchPreferred(stadium)
return true
end

function P.registerCapability(owner,kind,api)
owner=tostring(owner or "")
if owner=="" or owner==OWNER then return false,"invalid capability owner" end
if kind=="battleSpriteProvider" then kind="battleSprites" end
if kind=="battlePresenter" then kind="battlePresentation" end
local valid=(kind=="battleActors" and validActorApi(api))
or (kind=="battleSprites" and validSpriteApi(api))
or (kind=="battlePresentation" and validPresentationApi(api))
if not valid or not registeredCapabilities[kind] then return false,"unsupported capability" end
registeredCapabilities[kind][owner]=api
return true
end

function P.unregisterCapability(owner,kind)
owner=tostring(owner or "")
if kind=="battleSpriteProvider" then kind="battleSprites" end
if kind=="battlePresenter" then kind="battlePresentation" end
local bucket=registeredCapabilities[kind]
if not bucket then return false end
bucket[owner]=nil
return true
end

function P.prewarm()



local sh=moveFxShader()
return sh~=nil or P.moveFxShader==false
end

function P.status()
local _,id=battleArtHandle()
local stadium=stadiumService()
local actorStatus
if P.actorApi and type(P.actorApi.status)=="function" then
local ok,value=pcall(P.actorApi.status)
if ok then actorStatus=value end
end
local activeFx=P.moveFxActive[1]
local scaleStatus=activeFx and {moveId=activeFx.spec and activeFx.spec.moveId,style=activeFx.spatialStyle,role=activeFx.role,
groundField=activeFx.groundField==true,sourceVisualHeight=activeFx.sourceVisualHeight,targetVisualHeight=activeFx.targetVisualHeight,
fightDistance=activeFx.fightDistance,sourceUnits=activeFx.sourceUnits} or nil
return {registered=P.registered,id=P.id,preferredPatched=P.preferredPatched,
standaloneOnlyGateApplies=false,
registeredActorOwners=(function()
local out={}
for owner in pairs(registeredCapabilities.battleActors or {}) do out[#out+1]=owner end
table.sort(out);return out
end)(),
battleArt=id,battleArtWorld=battleArtWantsWorldSprites(),
stadiumActors=stadium and true or false,stadiumError=P.stadiumError,stadiumPending=P.stadiumPending,
retiringActorCount=#P.retiringActors,
moveFxActive=#P.moveFxActive,moveFxError=P.moveFxError,moveFxRenderFaults=P.moveFxRenderFaults or 0,moveFxScale=scaleStatus,
actorLifecycle="persistent-hit / detached-recall / faint-tail",
presentationMode=P.mode,presentationId=P.modeId,actorOwner=P.actorOwner,actorStatus=actorStatus,
spriteOwner=P.spriteOwner,spriteError=P.spriteError,externalError=P.externalError,
contract="CBE Arenas ON = CBE stage always; Models ON = GC6E01 actors; Models OFF = portable battleActors or resolved sprites (full battlePresentation only when Arenas OFF)"}
end

P._test=P._test or {}
P._test.sourceNativeSlot=sourceNativeSlot
P._test.particleIntensityAlpha=particleIntensityAlpha
P._test.particleShaderSource=MOVE_FX_PIXEL
P._test.particleColors=particleColors
P._test.particleAlphaCompare=particleAlphaCompare
P._test.particleImage=particleImage
P._test.relinquishMoveFx=relinquishMoveFx
P._test.drawParticleAt=drawParticleAt
P._test.drawTrailRibbon=drawTrailRibbon
P._test.stadiumActor=stadiumActor
P._test.actorVisible=actorVisible
P._test.actorGoneByBattle=actorGoneByBattle
P._test.beginPendingFaintReturn=beginPendingFaintReturn
P._test.syncStadiumActor=syncStadiumActor
P._test.retireStadiumActor=retireStadiumActor
P._test.doublesOpeningPending=doublesOpeningPending
P._test.particleTransitSpan=particleTransitSpan
function P:particleTransitSpan(moveId,role,entry) return particleTransitSpan(moveId,role,entry) end
local function particleTransitProgress(fx,p)
if not (fx and p and fx.sourceWorld and fx.targetWorld) then return nil end
local world=particleWorld(fx,p,p.position);if not world then return nil end
local lane=vsub(fx.targetWorld,fx.sourceWorld);local d2=vdot(lane,lane)
if d2<1e-8 then return nil end
return vdot(vsub(world,fx.sourceWorld),lane)/d2
end
P._test.particleTransitProgress=particleTransitProgress
function P:particleTransitProgress(fx,p) return particleTransitProgress(fx,p) end
P._test.combatGeometry=combatGeometry
P._test.sourceOwnerUnit=sourceOwnerUnit

function P:sourceNativeSlot(spec,role) return sourceNativeSlot(spec,role) end
installWazaHandlers()
function P:updateReleaseFx(context,dt) if context then updateMoveFx(context,dt) end end
function P:drawReleaseFx(context) if context then return drawMoveFx(context) end end
function P:clearReleaseFx()
for i=#self.moveFxActive,1,-1 do if self.moveFxActive[i].releaseGeometry then table.remove(self.moveFxActive,i) end end
end
function P:withDoublesPair(ctx,records,fn)
local previous=self.stadiumActors;local memo=self.doublesAttachmentMemo
self.stadiumActors=records;self.doublesAttachmentMemo={}
local ok,a,b=pcall(fn,ctx)
self.stadiumActors=previous;self.doublesAttachmentMemo=memo
if not ok then error(a) end;return a,b
end
function P:startDoublesWaza(ctx,spec,opts)
installWazaHandlers()
return WazaSequence:start(ctx,"player",spec,opts)
end
function P:hasDoublesWazaParticles(instance)
if not instance then return false end
for _,fx in ipairs(self.moveFxActive) do
if fx.wazaSerial==instance.serial and fx.vm and not fx.vm.done then return true end
end
return false
end
function P:clearDoublesWaza(ctx)
if WazaSequence then WazaSequence:finish(ctx,"doubles chapter complete") end
for i=#self.moveFxActive,1,-1 do if not self.moveFxActive[i].releaseGeometry then table.remove(self.moveFxActive,i) end end
end
return P
