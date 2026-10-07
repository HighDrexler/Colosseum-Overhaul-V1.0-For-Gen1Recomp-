local mod=...
local VERSION="3.0.1"
mod.exports.version=VERSION
mod.exports.releaseBuild="colosseum-overhaul-3.0.1"

local function package(path,arg)
local src=mod:read(path)
if not src then error("COLOSSEUM_OVERHAUL: missing "..path,0) end
local chunk,err=load(src,"@"..tostring(mod.path or mod.id).."/"..path)
if not chunk then error(err,0) end
return chunk(arg)
end




local NativeLauncherCompat=package("lib/NativeLauncherCompat.lua")
local launcherCompat=NativeLauncherCompat.install(mod)
local BuildProgressUI=package("lib/BuildProgressUI.lua")
local AudioFidelity=package("lib/AudioFidelity.lua")
local GeneratedCacheReset=package("lib/GeneratedCacheReset.lua")

local function platformOS()
if love and love.system and type(love.system.getOS)=="function" then
local ok,v=pcall(love.system.getOS);if ok and v then return tostring(v) end
end
return "Unknown"
end
local PLATFORM_OS=platformOS()
local IS_ANDROID=PLATFORM_OS=="Android"



local extractionStatus={state="NOT RUN",visualReady=false,audioReady=false,message=nil}
local sourceImported=false
local cacheGateOutcome=nil
local startupCachePolicyResolved=false
local startupExitRequested=false




local openColosseumDisc=nil
local PokemonExtractorRef=nil
local PKXMetadataRef=nil
local MoveFXExtractorRef=nil
local BuildPipelineRef=nil
local ColosseumPokemonMoveDataRef=nil
local ColosseumUIFontSourceRef=nil





local function runBuild(requestedBuildOptions)
ColosseumPokemonMoveDataRef=nil
ColosseumUIFontSourceRef=nil
if not (mod.imports and mod.cache) then
extractionStatus={state="HOST API MISSING",visualReady=false,audioReady=false,message="Colosseum Battle Environments requires Gen1Recomp required-import support with mod.imports/mod.cache."}
return
end
local info=mod.imports:info("pokemon_colosseum_usa")
sourceImported=info~=nil
if not info then
extractionStatus={state="ROM NOT IMPORTED",visualReady=false,audioReady=false,message="In the Gen1Recomp launcher, open MODS > Colosseum Battle Environments > IMPORT FILE.., select your Pokemon Colosseum USA GC6E01 disc image (raw ISO/GCM or GameCube CISO; the selected filename/extension does not matter once the launcher can validate it), then launch the game with CBE enabled. Current Gen1Recomp builds retain this source across CBE updates."}
return
end
local GXTexture=package("extract/GXTexture.lua")
local GameCubeDisc=package("extract/GameCubeDisc.lua")
local FSYS=package("extract/FSYS.lua")
local HSD=package("extract/HSD.lua",{GXTexture=GXTexture})
local PayloadPreserver=package("extract/PayloadPreserver.lua")
local ArenaBuilder=package("extract/ArenaBuilder.lua",{HSD=HSD,FSYS=FSYS,
ArenaAudienceProfile=package("lib/ArenaAudienceProfile.lua"),ArenaCacheIdentity=package("lib/ArenaCacheIdentity.lua"),PayloadPreserver=PayloadPreserver})
local TransitionBuilder=package("extract/TransitionBuilder.lua",{PayloadPreserver=PayloadPreserver})
local PortableMusyX=package("extract/PortableMusyX.lua")
local AudioProbe=package("extract/AudioProbe.lua",{FSYS=FSYS,PortableMusyX=PortableMusyX,AudioFidelity=AudioFidelity})
local WazaSfxBuilder=package("extract/WazaSfxBuilder.lua",{FSYS=FSYS,PortableMusyX=PortableMusyX})
local TrainerThrowSource=package("extract/TrainerThrowSource.lua")
local TrainerExtractor=package("extract/TrainerExtractor.lua",{HSD=HSD,FSYS=FSYS,PayloadPreserver=PayloadPreserver,TrainerThrowSource=TrainerThrowSource})
local ColosseumDex=package("lib/ColosseumDex.lua")
local ShinySupport=package("lib/ShinySupport.lua")
local PKXMetadata=package("extract/PKXMetadata.lua",{FSYS=FSYS,ColosseumDex=ColosseumDex,ShinySupport=ShinySupport})
local PokemonExtractor=package("extract/PokemonExtractor.lua",{HSD=HSD,FSYS=FSYS,ColosseumDex=ColosseumDex,PKXMetadata=PKXMetadata,ShinySupport=ShinySupport,PayloadPreserver=PayloadPreserver,PokemonMaterial=package("lib/PokemonMaterial.lua")})
local WazaSequenceExtractor=package("extract/WazaSequenceExtractor.lua")
local ColosseumSpeciesIndex=package("lib/ColosseumSpeciesIndex.lua")
local MoveFXExtractor=package("extract/MoveFXExtractor.lua",{FSYS=FSYS,GXTexture=GXTexture,HSD=HSD,WazaSequenceExtractor=WazaSequenceExtractor,PayloadPreserver=PayloadPreserver,ColosseumSpeciesIndex=ColosseumSpeciesIndex})
local ColosseumPokemonMoveData=package("extract/ColosseumPokemonMoveData.lua",{FSYS=FSYS,ColosseumSpeciesIndex=ColosseumSpeciesIndex})
local ColosseumUIFont=package("extract/ColosseumUIFont.lua")
local FormatProbe=package("extract/FormatProbe.lua",{FSYS=FSYS,HSD=HSD,WazaSequenceExtractor=WazaSequenceExtractor})
local CameraProbe=package("extract/CameraProbe.lua",{FSYS=FSYS,HSD=HSD})
PokemonExtractorRef=PokemonExtractor
PKXMetadataRef=PKXMetadata
MoveFXExtractorRef=MoveFXExtractor



local residentDisc=nil
openColosseumDisc=function()
if residentDisc then return residentDisc end
local disc,why=GameCubeDisc.open(mod)
if disc then residentDisc=disc end
return disc,why
end
local BuildPipeline=package("extract/BuildPipeline.lua",{
GameCubeDisc=GameCubeDisc,FSYS=FSYS,GXTexture=GXTexture,HSD=HSD,
ArenaBuilder=ArenaBuilder,TrainerExtractor=TrainerExtractor,
TransitionBuilder=TransitionBuilder,AudioProbe=AudioProbe,WazaSfxBuilder=WazaSfxBuilder,
PokemonExtractor=PokemonExtractor,MoveFXExtractor=MoveFXExtractor,FormatProbe=FormatProbe,CameraProbe=CameraProbe,ColosseumDex=ColosseumDex,
LauncherCompat=launcherCompat,BuildVersion=VERSION,PlatformOS=PLATFORM_OS,GeneratedCacheReset=GeneratedCacheReset,
})
BuildPipelineRef=BuildPipeline
local CueBuilder=package("extract/BattleAudioBuilder.lua",{FSYS=FSYS,PortableMusyX=PortableMusyX,
BattleAudioSpec=package("lib/BattleAudioSpec.lua"),AudioFidelity=AudioFidelity})
local FidelityBuilder=package("extract/AudioFidelityBuilder.lua",{FSYS=FSYS,PortableMusyX=PortableMusyX,
AudioProbe=AudioProbe,BattleAudioSpec=package("lib/BattleAudioSpec.lua"),BattleAudioBuilder=CueBuilder,AudioFidelity=AudioFidelity,PayloadPreserver=PayloadPreserver})








local buildOptions=type(requestedBuildOptions)=="table" and requestedBuildOptions or nil
if not startupCachePolicyResolved then
local hasExisting=BuildPipeline.hasGeneratedCache(mod)==true
local safeReuse=hasExisting and BuildPipeline.canReuseWithoutPrompt and BuildPipeline.canReuseWithoutPrompt(mod)==true
if safeReuse and not (buildOptions and buildOptions.forceRebuild==true) then
startupCachePolicyResolved=true;cacheGateOutcome="auto-reuse"
buildOptions=buildOptions or {};buildOptions.verifiedStartupReady=true
elseif hasExisting then
startupCachePolicyResolved=true;cacheGateOutcome="auto-repair"
else
startupCachePolicyResolved=true
end
end


FidelityBuilder.recover(mod)
extractionStatus={state="RUNNING",visualReady=false,audioReady=false,message="Starting GC6E01 source build."}
local okPipeline,result=pcall(BuildPipeline.run,mod,function(label,current,total)
extractionStatus.state="RUNNING";extractionStatus.message=tostring(label);extractionStatus.current=current;extractionStatus.total=total
BuildProgressUI.update(label,current,total)
if mod.log and mod.log.info then pcall(mod.log.info,mod.log,"CBE source build: %s (%s/%s)",tostring(label),tostring(current or "?"),tostring(total or "?")) end
end,buildOptions)
if not okPipeline then error(result,0) end
extractionStatus=result or extractionStatus





local okMoveData,moveData=pcall(ColosseumPokemonMoveData.load,mod,openColosseumDisc)
if okMoveData then ColosseumPokemonMoveDataRef=moveData else
ColosseumPokemonMoveDataRef={error=tostring(moveData),discId="GC6E01",source="GC6E01 MOVE PREP extraction failed"}
if mod.log and mod.log.warn then pcall(mod.log.warn,mod.log,"CBE MOVE PREP source catalog unavailable: %s",tostring(moveData)) end
end




local okUIFont,fontData=pcall(ColosseumUIFont.load,mod,openColosseumDisc)
if okUIFont and fontData then ColosseumUIFontSourceRef=fontData else
ColosseumUIFontSourceRef={error=tostring(fontData),discId="GC6E01",source="GC6E01 UI font-0 extraction failed"}
if mod.log and mod.log.warn then pcall(mod.log.warn,mod.log,"CBE retail Colosseum UI font unavailable: %s",tostring(fontData)) end
end
if extractionStatus.audioReady==true then
local okCues,cues=pcall(CueBuilder.run,mod,openColosseumDisc,function(label,current,total)
BuildProgressUI.update(label,current,total)
end)
extractionStatus.battleAudio=okCues and cues or {ready=false,error=tostring(cues)}
if not(okCues and cues.ready) and mod.log and mod.log.warn then
pcall(mod.log.warn,mod.log,"CBE battle cue preparation incomplete; unavailable cues retain native audio. Existing caches preserved.")
end
end
if extractionStatus.audioReady==true and AudioFidelity.pending(mod) then
local okFidelity,result=pcall(FidelityBuilder.run,mod,openColosseumDisc,function(label,current,total)
BuildProgressUI.update(label,current,total)
end)
extractionStatus.audioFidelity=okFidelity and result or {ready=false,error=tostring(result)}


if not okFidelity then FidelityBuilder.recover(mod) end
if okFidelity and result.recoveryRequired then error(result.error,0) end
if not(okFidelity and result.ready) and mod.log and mod.log.warn then
pcall(mod.log.warn,mod.log,"Audio fidelity update incomplete; committed tracks retained. See build/audio_fidelity_v1/status.txt")
end
end
BuildProgressUI.finish(extractionStatus.state,extractionStatus.message)
if extractionStatus.state=="FAILED" and mod.log and mod.log.error then pcall(mod.log.error,mod.log,"CBE source build failed: %s",tostring(extractionStatus.message))
elseif mod.log and mod.log.info then pcall(mod.log.info,mod.log,"CBE source build: %s",tostring(extractionStatus.state)) end
end
local okBuild,buildErr=pcall(runBuild)
if not okBuild then
extractionStatus={state="FAILED",visualReady=false,audioReady=false,message=tostring(buildErr)}
BuildProgressUI.finish("FAILED",tostring(buildErr))
if mod.cache then pcall(mod.cache.write,mod.cache,"build/error.txt",tostring(buildErr).."\n") end
end






while sourceImported and not startupExitRequested and (extractionStatus.visualReady~=true or extractionStatus.audioReady~=true) do
local action=BuildProgressUI.failureGate(extractionStatus.state,extractionStatus.message,extractionStatus.trainerFirstError,extractionStatus.trainerSourceError)
if action=="retry" then
local okRetry,retryErr=pcall(runBuild)
if not okRetry then
extractionStatus={state="FAILED",visualReady=false,audioReady=false,message=tostring(retryErr)}
BuildProgressUI.finish("FAILED",tostring(retryErr))
if mod.cache then pcall(mod.cache.write,mod.cache,"build/error.txt",tostring(retryErr).."\n") end
end
elseif action=="delete_rebuild" then





local stateText=tostring(extractionStatus.state or ""):upper()
local arenaFailure=stateText:find("ARENA",1,true)~=nil
local resetFn=(arenaFailure and GeneratedCacheReset.resetArenas) or GeneratedCacheReset.reset
local okCall,resetOK,resetMessage=pcall(resetFn,mod)
if not okCall or resetOK~=true then
local why=tostring(okCall and resetMessage or resetOK)
extractionStatus={state="CACHE DELETE FAILED",visualReady=false,audioReady=false,message=why}
BuildProgressUI.finish("CACHE DELETE FAILED",why)
else
cacheGateOutcome=arenaFailure and "failure-arena-delete-rebuild" or "failure-delete-rebuild"



local okRetry,retryErr=pcall(runBuild)
if not okRetry then
extractionStatus={state="FAILED",visualReady=false,audioReady=false,message=tostring(retryErr)}
BuildProgressUI.finish("FAILED",tostring(retryErr))
if mod.cache then pcall(mod.cache.write,mod.cache,"build/error.txt",tostring(retryErr).."\n") end
end
end
else
cacheGateOutcome=action
break
end
end

local runtimeAllowed=extractionStatus.visualReady==true and extractionStatus.audioReady==true

local function module(name,arg)
return package("lib/"..name..".lua",arg)
end
local namespace={mod=mod,FALLBACK=nil,engineRequire=require,


PayloadPreserver=package("extract/PayloadPreserver.lua"),GeneratedCacheReset=GeneratedCacheReset}
local function loadModule(name,arg)
local value=module(name,arg==nil and namespace or arg)
namespace[name]=value
return value
end

local Mat4=module("Mat4");namespace.Mat4=Mat4
loadModule("GeneratedAssets")
if PokemonExtractorRef and type(PokemonExtractorRef.installGeneratedAssets)=="function" then
pcall(PokemonExtractorRef.installGeneratedAssets,namespace.GeneratedAssets)
end
loadModule("RuntimeMeshCache")
loadModule("WorkBudget")
loadModule("FrameWork")
namespace.MoveFXExtractor=MoveFXExtractorRef


MoveFXExtractorRef.runtime=namespace
loadModule("WazaPhasePolicy")
local MoveFXVM=loadModule("MoveFXVM")
loadModule("MoveFXSourceTravel")
local WazaSequenceRuntime=loadModule("WazaSequenceRuntime")
local GenerationCompat=loadModule("GenerationCompat")
local TrainerRig=loadModule("TrainerRig")

loadModule("TrainerMorph")
local TrainerPerformance=loadModule("TrainerPerformance")
loadModule("BattleSides")
local FreeLookCamera=loadModule("FreeLookCamera")
local BattleAutoProgress=loadModule("BattleAutoProgress")
local BattleDirector=loadModule("BattleDirector")
local ModLookup=loadModule("ModLookup")
local TrainerRoster=loadModule("TrainerRoster")
local Trainer=loadModule("Trainer")
local PlayerTrainer=loadModule("PlayerTrainer")
local NativeTrainerSprites=loadModule("NativeTrainerSprites")
local MoveFXOwnership=loadModule("MoveFXOwnership")
local ArenaCatalog=loadModule("ArenaCatalog")
local ArenaAudienceProfile=loadModule("ArenaAudienceProfile")
local ArenaCacheIdentity=loadModule("ArenaCacheIdentity")
local BattleArtBridge=loadModule("BattleArtBridge")
loadModule("ShinySupport")
loadModule("ModelIdentity")
local CurrentSpriteModels=loadModule("CurrentSpriteModels")
loadModule("ColosseumDex")
loadModule("ColosseumDexNames")
loadModule("ColosseumPortraitIndex")
loadModule("ColosseumPortraitCatalog")
loadModule("ColosseumSpeciesIndex")
namespace.ColosseumPokemonMoveData=ColosseumPokemonMoveDataRef
namespace.ColosseumFontSource=ColosseumUIFontSourceRef
local ColosseumFont=loadModule("ColosseumFont")
mod.exports.colosseumFont=ColosseumFont
namespace.UIPresentation=module("UI/Presentation")
mod.exports.uiPresentation=namespace.UIPresentation
namespace.MenuPresentation=module("UI/MenuPresentation")
mod.exports.menuPresentation=namespace.MenuPresentation
namespace.SummaryPresentation=module("UI/SummaryPresentation")
mod.exports.summaryPresentation=namespace.SummaryPresentation
mod.exports.colosseumFontStatus=ColosseumFont.status()
local ColosseumVerifiedMoves=loadModule("ColosseumVerifiedMoves")
namespace.ColosseumVerifiedMoveStatus=GenerationCompat.current()==3 and {generation=3,installed=0,native=true} or ColosseumVerifiedMoves.install(mod,GenerationCompat.current())
loadModule("ColosseumMoveCatalog")
local ColosseumMoveTMs=loadModule("ColosseumMoveTMs")
namespace.ColosseumMoveTMStatus=GenerationCompat.current()==3 and {generation=3,native=true} or ColosseumMoveTMs.install(mod,GenerationCompat.current())
mod.exports.colosseumMoveTMStatus=namespace.ColosseumMoveTMStatus
loadModule("ColosseumDexIdentity")
loadModule("ColosseumDexOwnedSidecar")
loadModule("ColosseumDexCatalog")
loadModule("ColosseumDexState")
loadModule("ColosseumDexOwnedStorage")
local ColosseumDexRuntime=loadModule("ColosseumDexRuntime")
local ColosseumDexMarkBridge=loadModule("ColosseumDexMarkBridge")
loadModule("ExpandedWildEncounters")
loadModule("ColosseumDexHabitats")
local ColosseumDexSpecies=loadModule("ColosseumDexSpecies")


namespace.ColosseumDexSpeciesStatus=GenerationCompat.current()==3 and {generation=3,native=true,registered=0} or ColosseumDexSpecies.register(mod,GenerationCompat.current())
local ColosseumDexSaveBridge=loadModule("ColosseumDexSaveBridge")
local ColosseumDexGameplay=loadModule("ColosseumDexGameplay")



if GenerationCompat.current()~=3 then
ColosseumDexSaveBridge.install(mod,GenerationCompat.current())
ColosseumDexMarkBridge.install()
end
mod.exports.colosseumDexSpawns=ColosseumDexGameplay.status
loadModule("PokemonMaterial")
loadModule("PokemonSourceScale")
local PokemonActors=loadModule("PokemonActors")
loadModule("RelicPresentation")
loadModule("SummitNumerals")
local Arena=loadModule("Arena")
loadModule("CameraPacing")
local Camera=loadModule("Camera")
local Music=loadModule("Music")





namespace.ColosseumMusic=Music
loadModule("BattleAudioSpec")
local BattleAudio=loadModule("BattleAudio")
local WazaAudioRuntime=loadModule("WazaAudioRuntime")
loadModule("WazaCameraFov")
loadModule("WazaCameraParams")
local WazaHandlers=loadModule("WazaHandlers")
local BattleMenuUI=loadModule("BattleMenuUI")
local CacheManager=loadModule("CacheManager")
local BattleSettings=loadModule("BattleSettings")
local BattleTempo=loadModule("BattleTempo")
namespace.VERSION=VERSION
loadModule("FxDiagnostics")
local ExpShare=loadModule("ExpShare")
loadModule("AbilityData")
local Abilities=loadModule("Abilities")
loadModule("AbilityWeather")
local AbilityEffectsGen1=loadModule("AbilityEffectsGen1")
local AbilityEffectsGen2=loadModule("AbilityEffectsGen2")
local AbilityLifecycle=loadModule("AbilityLifecycle")
local Transition=loadModule("Transition")
local StandaloneHost=loadModule("StandaloneHost")
local StadiumBridge=loadModule("StadiumBridge")
local ResidentPrewarm=loadModule("ResidentPrewarm")
local BattleRuntime=loadModule("BattleRuntime")
namespace.BattleRuntime=BattleRuntime
namespace.DoublesCore=module("doubles/Core",namespace)
namespace.DoublesItems=module("doubles/Items",namespace)
namespace.DoublesNativeAdapter=module("doubles/NativeAdapter",namespace)
namespace.DoublesMovePresentation=module("doubles/MovePresentation",namespace)
namespace.ReleasePresentation=module("doubles/ReleasePresentation",namespace)
namespace.DoublesCamera=module("doubles/CameraDirector",namespace)
namespace.DoublesPresenter=module("doubles/Presenter",namespace)
namespace.DoublesRuntime=module("doubles/Runtime",namespace)
namespace.BossIntro=module("BossIntro",namespace)






namespace.MtBattleSaveState=module("MtBattle/SaveState",namespace)
namespace.MtBattleSeedManager=module("MtBattle/SeedManager",namespace)



namespace.MtBattleSummitVariation=module("MtBattle/SummitVariation",namespace)



namespace.MtBattleBattleData=module("MtBattle/BattleData",namespace)
namespace.MtBattleLevelClone=module("MtBattle/LevelClone",namespace)
namespace.MtBattleRentalPool=module("MtBattle/RentalPool",namespace)
namespace.MtBattleMovePrep=module("MtBattle/MovePrep",namespace)
namespace.MtBattleLevelLock=module("MtBattle/LevelLock",namespace)
namespace.MtBattleXPBank=module("MtBattle/XPBank",namespace)
namespace.MtBattleBattlePoints=module("MtBattle/BattlePoints",namespace)
namespace.MtBattleChallengeBag=module("MtBattle/ChallengeBag",namespace)



namespace.MtBattleArchetypes=module("MtBattle/Archetypes",namespace)
namespace.MtBattleFingerprint=module("MtBattle/Fingerprint",namespace)
namespace.MtBattleAntiRepeat=module("MtBattle/AntiRepeat",namespace)
namespace.MtBattleDifficulty=module("MtBattle/Difficulty",namespace)
namespace.MtBattleRosterCore=module("MtBattle/RosterCore",namespace)





namespace.MtBattleRecordsManager=module("MtBattle/RecordsManager",namespace)
namespace.MtBattlePlayerBehaviorTracker=module("MtBattle/PlayerBehaviorTracker",namespace)





namespace.MtBattleShinyRollManager=module("MtBattle/ShinyRollManager",namespace)
namespace.MtBattleAreaLeaderManager=module("MtBattle/AreaLeaderManager",namespace)
namespace.MtBattleTrainerIdentityGenerator=module("MtBattle/TrainerIdentityGenerator",namespace)




namespace.MtBattleSpecialFights=module("MtBattle/SpecialFights",namespace)
namespace.MtBattleTeamGenGen1=module("MtBattle/TeamGenGen1",namespace)
namespace.MtBattleTeamGenGen2=module("MtBattle/TeamGenGen2",namespace)





namespace.MtBattleTrainerPoolG1=module("MtBattle/TrainerPoolG1",namespace)







namespace.MtBattleBattleObserver=module("MtBattle/BattleObserver",namespace)
namespace.MtBattleBattleLauncher=module("MtBattle/BattleLauncher",namespace)
namespace.MtBattleRunController=module("MtBattle/RunController",namespace)








namespace.MtBattleHubStage=module("MtBattle/HubStage",namespace)
namespace.MtBattleMobileHubUI=module("MtBattle/MobileHubUI",namespace)
namespace.MtBattleHubScreens=module("MtBattle/HubScreens",namespace)





namespace.MtBattleEntryFlow=module("MtBattle/EntryFlow",namespace)
namespace.MtBattleOverworldGate=module("MtBattle/OverworldGate",namespace)
namespace.MtBattleFinaleIntro=module("MtBattle/FinaleIntro",namespace)
namespace.MtBattleXPDistribution=module("MtBattle/XPDistribution",namespace)



namespace.MtBattlePostBattleFlow=module("MtBattle/PostBattleFlow",namespace)
namespace.MtBattleSuspendRun=module("MtBattle/SuspendRun",namespace)



namespace.MtBattleScoutingSystem=module("MtBattle/ScoutingSystem",namespace)















local mtBattleHostGeneration=GenerationCompat.current()
if mtBattleHostGeneration==1 and mod.content and mod.content.trainers and mod.content.ai_classes then
namespace.MtBattleTrainerPoolG1.install(mod,"RATTATA")
end







if GenerationCompat.current()~=3 then namespace.MtBattleOverworldGate.install(mod,{trainerModel="wes"}) end
loadModule("QuickCachePlanner")
loadModule("CacheScreen")
local BattleCache=loadModule("BattleCache")

if GenerationCompat.current()==3 then
namespace.Gen3Runtime=module("Gen3/Runtime",namespace)
namespace.Gen3Audio=module("Gen3/Audio",namespace)
namespace.Gen3Presentation=module("Gen3/Presentation",namespace)
namespace.Gen3BattleCamera=module("Gen3/BattleCamera",namespace)
namespace.Gen3Capture=module("Gen3/Capture",namespace)
namespace.Gen3Overlay=module("Gen3/Overlay",namespace)
namespace.Gen3Screens=module("Gen3/Screens",namespace)
namespace.Gen3FieldUI=module("Gen3/FieldUI",namespace)
namespace.Gen3FRLGStarters=module("Gen3/FRLGStarters",namespace)
namespace.Gen3ModManager=module("Gen3/ModManager",namespace)
namespace.Gen3ModelCamera=module("Gen3/ModelCamera",namespace)
namespace.Gen3MoveMemory=module("Gen3/MoveMemory",namespace)
namespace.Gen3EvolutionModels=module("Gen3/EvolutionModels",namespace)
namespace.Gen3UI=module("Gen3/UI",namespace)
namespace.Gen3MenuScene=module("Gen3/MenuScene",namespace)
namespace.Gen3Menus=module("Gen3/Menus",namespace)
namespace.Gen3Summary=module("Gen3/Summary",namespace)
namespace.Gen3Services=module("Gen3/Services",namespace)
namespace.Gen3StorageUI=module("Gen3/StorageUI",namespace)
namespace.Gen3PokedexUI=module("Gen3/PokedexUI",namespace)
namespace.Gen3ProgressUI=module("Gen3/ProgressUI",namespace)
namespace.Gen3PokenavUI=module("Gen3/PokenavUI",namespace)
namespace.Gen3NavigationUI=module("Gen3/NavigationUI",namespace)
namespace.Gen3Challenge=module("Gen3/Challenge",namespace)
namespace.Gen3MtBattleHub=module("Gen3/MtBattleHub",namespace)
namespace.Gen3LeagueScientist=module("Gen3/LeagueScientist",namespace)
namespace.Gen3Gameplay=module("Gen3/Gameplay",namespace)
mod.exports.gen3Status=namespace.Gen3Runtime.status
end

local function installRuntime(force)
ExpShare.install(mod)


if WazaHandlers and type(WazaHandlers.install)=="function" then WazaHandlers.install() end
if GenerationCompat.current()==3 then
PokemonActors.install(PokemonExtractorRef,openColosseumDisc,CurrentSpriteModels,PKXMetadataRef)
if MoveFXExtractorRef then MoveFXExtractorRef.install(mod,openColosseumDisc) end
CurrentSpriteModels.registerCapability("COLOSSEUM_BATTLE_ENVIRONMENTS/pokemon","battleActors",PokemonActors.service)
Music.install(mod);Music.attachGame(mod.game);BattleTempo.attach(mod.game)
namespace.Gen3Runtime.install()
namespace.Gen3Gameplay.install()
return
end
StadiumBridge.install()
Music.install(mod)
Music.attachGame(mod.game)
BattleTempo.attach(mod.game)
BattleAudio.install(mod)
namespace.MtBattleLevelLock.install(mod)
BattleSettings.install(mod,Trainer,Music,ArenaCatalog,BattleMenuUI,CacheManager,TrainerRoster,GenerationCompat,AudioFidelity)


local abilityGeneration=GenerationCompat.current()
if abilityGeneration==2 then AbilityEffectsGen2.installGlobal()
else AbilityEffectsGen1.installGlobal() end
AbilityLifecycle.install(mod,abilityGeneration)





namespace.ColosseumVerifiedMoveRuntime=ColosseumVerifiedMoves.installRuntime(mod,abilityGeneration)


ColosseumDexGameplay.install(mod,abilityGeneration)
if ArenaCatalog.sync then ArenaCatalog.sync(mod.game) end
Transition.install(mod)
StandaloneHost.install(force)
BattleArtBridge.install()
ColosseumDexMarkBridge.install()







PokemonActors.install(PokemonExtractorRef,openColosseumDisc,CurrentSpriteModels,PKXMetadataRef)
if MoveFXExtractorRef and type(MoveFXExtractorRef.install)=="function" then
MoveFXExtractorRef.install(mod,openColosseumDisc)
end
CurrentSpriteModels.registerCapability(
"COLOSSEUM_BATTLE_ENVIRONMENTS/pokemon","battleActors",PokemonActors.service)



if not CurrentSpriteModels.__cbePokemonDebugWrapped then
local originalDrawWorld=CurrentSpriteModels.drawWorld
CurrentSpriteModels.drawWorld=function(self,context)
local ok,result=pcall(originalDrawWorld,self,context)
pcall(PokemonActors.debugFrame)
if not ok then error(result,0) end
return result
end
CurrentSpriteModels.__cbePokemonDebugWrapped=true
end
MoveFXOwnership.install()
BattleRuntime.install()
namespace.MtBattlePostBattleFlow.install(mod)
namespace.DoublesRuntime.install()


namespace.MtBattleSuspendRun.install(mod)
BattleAutoProgress.install()
namespace.BossIntro.install()
BattleCache.install()
end

if runtimeAllowed then
if GenerationCompat.current()~=3 then FreeLookCamera.install() end
if GenerationCompat.current()~=3 then NativeTrainerSprites.install() end
installRuntime(false)
if mod.events and type(mod.events.on)=="function" then
mod.events:on("mods.loaded",function(payload)
if ModLookup and type(ModLookup.setLoader)=="function" then
ModLookup.setLoader(type(payload)=="table" and payload.loader or nil)
end
installRuntime(true)
end)
mod.events:on("game.ready",function(payload)
local game=type(payload)=="table" and payload.game or nil
if game then
BattleTempo.attach(game)
Music.attachGame(game)
BattleAudio.attachGame(game)
if ArenaCatalog.sync then ArenaCatalog.sync(game) end
if GenerationCompat.current()==3 then namespace.Gen3Runtime.attach(game);return end
if BattleRuntime.attachFrame then BattleRuntime.attachFrame(game) end






if ResidentPrewarm and type(ResidentPrewarm.queueStartup)=="function" then
pcall(ResidentPrewarm.queueStartup,game)
end

if IS_ANDROID and mod.log and mod.log.info then
pcall(mod.log.info,mod.log,"CBE Android performance-polish policy active: state-change guard + single paced resident-warm queue + runtime mesh sidecars + deferred mobile framebuffer")
end
end
end)
end
elseif mod.log and mod.log.warn then
pcall(mod.log.warn,mod.log,"CBE runtime withheld because required generated visual/audio cache is not ready (%s)",tostring(cacheGateOutcome or extractionStatus.state))
end




mod.exports.battleAudioStatus=function() return BattleAudio.status() end
mod.exports.audioFidelityStatus=function() return AudioFidelity.status(mod) end

mod.exports.probeFormats=function()
if not BuildPipelineRef then return false,"build pipeline unavailable (source not imported?)" end
local ok,result,note=pcall(BuildPipelineRef.ensureFormatProbe,mod,nil,true)
if not ok then return false,tostring(result) end
return result==true,tostring(note or ""),"build/format_probe.txt"
end





mod.exports.rebuildPokemon=function()
local ok,result=pcall(PokemonActors.rebuildSpecies)
if not ok then return false,tostring(result) end
return result==true,"Pokemon runtime refreshed; saved generated Pokemon cache retained"
end

mod.exports.rebuild=function()


local ok2,err2=pcall(runBuild,{forceRebuild=true});if not ok2 then return false,tostring(err2) end
CacheManager.resetRuntime();return extractionStatus.visualReady,extractionStatus
end







mod.exports.presentationOwnership=function(battle)
local host=StandaloneHost.status()
local runtime=BattleRuntime.status()
local trainer=Trainer:status()
local wild=type(battle)=="table" and battle.wild==true
local world=host.active==true or runtime.active==true
return {
version=1,
world=world,
trainer=(not wild) and (host.active==true or trainer.active==true) or false,
standalone=host.active==true,
runtime=runtime.active==true,
}
end




mod.exports.status=function()
local stadium=StadiumBridge.status()
return {version=VERSION,registered=stadium.registered,stadiumDelegated=stadium.delegated,arenaProviderId=stadium.arenaProviderId,cameraProviderId=stadium.cameraProviderId,stadium=stadium,
runtime=BattleRuntime.status(),doubles=namespace.DoublesRuntime.service.status(),battleDirector=BattleDirector:status(),trainerRig=TrainerRig:status(),trainerPerformance=TrainerPerformance.status(),trainerRoster=TrainerRoster:status(),arena=Arena:status(),arenaCatalog=ArenaCatalog.status(mod.game,nil),trainer=Trainer:status(),playerTrainer=PlayerTrainer:status(),camera=Camera:status(),music=Music.status(),settings=BattleSettings.status(mod.game),cache=CacheManager.status(),extraction=extractionStatus,launcherImport=launcherCompat,battleMenuUI=BattleMenuUI.status(),transition=Transition.status(),nativeTrainerSprites=NativeTrainerSprites.status(),moveFxOwnership=MoveFXOwnership.status(),moveFxExtractor=MoveFXExtractorRef and MoveFXExtractorRef.status and MoveFXExtractorRef.status() or nil,moveFxVM={version=MoveFXVM.version,source=MoveFXVM.source},wazaSequenceRuntime=WazaSequenceRuntime and WazaSequenceRuntime.status and WazaSequenceRuntime:status() or nil,wazaHandlers=WazaHandlers and WazaHandlers.status and WazaHandlers.status() or nil,wazaAudio=WazaAudioRuntime and WazaAudioRuntime.status and WazaAudioRuntime:status() or nil,standaloneHost=StandaloneHost.status(),battleArtBridge=BattleArtBridge.status(),currentSpriteModels=CurrentSpriteModels.status(),pokemonActors=PokemonActors.status(),residentPrewarm=ResidentPrewarm and ResidentPrewarm.status and ResidentPrewarm.status() or nil,cacheGate={runtimeAllowed=runtimeAllowed,outcome=cacheGateOutcome}}
end
mod.exports.battleCompatibility={
version=1,
capabilities={sprites="battleSprites",actors="battleActors",presentation="battlePresentation",world="battleWorld"},
register=function(owner,kind,provider) return CurrentSpriteModels.registerCapability(owner,kind,provider) end,
unregister=function(owner,kind) return CurrentSpriteModels.unregisterCapability(owner,kind) end,
}



mod.exports.colosseumDex={
version=ColosseumDexRuntime.VERSION,maxDex=ColosseumDexRuntime.MAX_DEX,
registry=function(_,request)
request=type(request)=="table" and request or {}
return ColosseumDexRuntime.registry(request.game or mod.game,request)
end,
snapshot=function(_,request)
request=type(request)=="table" and request or {}
return ColosseumDexRuntime.snapshot(request.game or mod.game,request)
end,
catalog=function(_,request)
request=type(request)=="table" and request or {}
return ColosseumDexRuntime.catalog(request.game or mod.game,request)
end,
listItems=function(_,request)
request=type(request)=="table" and request or {}
return ColosseumDexRuntime.listItems(request.game or mod.game,request)
end,
mark=function(_,save,generation,registry,identity,kind)
return ColosseumDexRuntime.mark(save,generation,registry,identity,kind)
end,
prepareOwnedWrite=function(_,save,generation,registry)
return ColosseumDexRuntime.prepareOwnedWrite(save,generation,registry)
end,
hydrateOwned=function(_,save,generation,registry)
return ColosseumDexRuntime.hydrateOwned(save,generation,registry)
end,
habitats=function(_,request)
request=type(request)=="table" and request or {}
return namespace.ColosseumDexHabitats.locations(request.game or mod.game,request.species,request)
end,
spawnStatus=function() return ColosseumDexGameplay.status() end,
persistenceStatus=function() return ColosseumDexRuntime.persistenceStatus() end,
}




local function cbeInformationContext(request)
request=type(request)=="table" and request or {}
local game=request.game or mod.game
local mon=request.mon or request.pokemon
local battler=request.battler
if type(battler)~="table" and type(mon)=="table" then battler={mon=mon} end
local enabled=true
if BattleSettings and type(BattleSettings.pokemonModelsEnabled)=="function" then
local ok,value=pcall(BattleSettings.pokemonModelsEnabled,game)
enabled=(not ok) or value~=false
end
local context={
apiVersion=1,game=game,battle=nil,
sides={player={battler=battler},enemy={battler=nil}},
phase="information",progress=1,groundY=0,
services={cbeStandalone=true,informationSurface=true,informationAnimation=true},
}
if not enabled then return nil,"cbe-pokemon-models-disabled",context end
return context,nil
end





mod.exports.abilities={
version=1,
enabled=function() return Abilities.enabled(mod.game) end,
speciesLabel=function(dex) return Abilities.speciesLabel(dex) end,
nameFor=function(id) return Abilities.displayName(id) end,
resolve=function(mon,def)
if not mon then return nil end
return Abilities.ensure(mon, Abilities.dexOf(mon,def))
end,
}

mod.exports.battleCache={version=4,status=function()return BattleCache.status()end,


prepare=function(game)return BattleCache.openMenu(game or mod.game)end,
prepareStartup=function(game)return BattleCache.requestStartup(game or mod.game)end,
prepareQuick=function(game)return BattleCache.openQuick(game or mod.game)end,
prepareFull=function(game)return BattleCache.openFull(game or mod.game)end,
openMenu=function(game)return BattleCache.openMenu(game or mod.game)end}
mod.exports.informationModels={
version=7,
selected=function(_,request)
return BattleCache.enabled(request and request.game or mod.game)
end,
resolve=function(_,request)
if not runtimeAllowed then return nil,"cbe-runtime-unavailable" end
return CurrentSpriteModels.informationActorProvider(request)
end,
resolveSelected=function(_,request)
if not runtimeAllowed then return nil,"cbe-runtime-unavailable" end
return CurrentSpriteModels.informationActorProvider(request)
end,
resolveColosseum=function(_,request)
if not runtimeAllowed then return nil,"cbe-runtime-unavailable" end
local context,reason=cbeInformationContext(request)
if not context then return nil,reason end
return PokemonActors.service,"cbe:colosseum-pokemon",context,mod.id
end,





resolveShowroom=function(_,request)
if not runtimeAllowed then return nil,"cbe-runtime-unavailable" end
request=type(request)=="table" and request or {}
local game=request.game or mod.game
local mon=request.mon or request.pokemon
local battler=request.battler
if type(battler)~="table" and type(mon)=="table" then battler={mon=mon} end
local context={
apiVersion=1,game=game,battle=nil,
sides={player={battler=battler},enemy={battler=nil}},
phase="information",progress=1,groundY=0,
services={cbeStandalone=true,informationSurface=true,informationAnimation=true,showroom=true},
}
return PokemonActors.service,"cbe:colosseum-pokemon",context,mod.id
end,






touchViewer=function(_,seconds,reason)
if not runtimeAllowed or not (ResidentPrewarm and type(ResidentPrewarm.touchViewer)=="function") then return false end
return ResidentPrewarm.touchViewer(seconds,reason)
end,
requestResident=function(_,request)
if not runtimeAllowed then return false,"cbe-runtime-unavailable" end
request=type(request)=="table" and request or {}
local game=request.game or mod.game
local mon=request.mon or request.pokemon
local battler=request.battler
if type(battler)~="table" and type(mon)=="table" then battler=mon end
if not (ResidentPrewarm and type(ResidentPrewarm.queueInformation)=="function") then
return false,"resident-prewarm-unavailable"
end
return ResidentPrewarm.queueInformation(game,battler,request.kind)
end,
workStatus=function(_,request)
request=request or {}
return PokemonActors.informationWorkStatus(request.game or mod.game,request.mon or request.battler)
end,
warmStatus=function(_,request)
request=type(request)=="table" and request or {}
local game=request.game or mod.game
local mon=request.mon or request.pokemon
local battler=request.battler
if type(battler)~="table" and type(mon)=="table" then battler=mon end
if PokemonActors and type(PokemonActors.informationWarmStatus)=="function" then
return PokemonActors.informationWarmStatus(game,battler)
end
return nil
end,



setAnimation=function(_,actor,enabled)
if type(actor)~="table" then return false end
actor.informationAnimation=enabled==true
if enabled then
actor._informationIdleNextCheck=nil
end
return true
end,
}

mod.exports.controls={mouseOrbit="LMB DRAG",mouseDolly="RMB DRAG",mouseLens="SHIFT+RMB DRAG",mousePan="MMB DRAG",toggle="F8",orbitLeft="J",orbitRight="L",raise="I",lower="K",zoomIn="U",zoomOut="O",lensNarrow="N",lensWide="M",reset="HOME"}




mod.exports.freeLookControls={version=2,setting="FREE LOOK CAMERA",mouseOrbit="RMB DRAG",
mouseDolly="WHEEL / SHIFT+RMB DRAG",mousePan="MMB DRAG",touchOrbit="ONE-FINGER DRAG",
touchDolly="PINCH",touchPan="TWO-FINGER DRAG",reset="HOME",doublesPersistent=true,
ownership="additive-to-live-cinematic",gestureRegion="CENTRAL ARENA"}












local function loadEntryChunk(path)
local src=mod:read(path)
if not src then error("COLOSSEUM_OVERHAUL: missing "..path,0) end
local chunk,err=load(src,"@"..tostring(mod.path or mod.id).."/"..path)
if not chunk then error(err,0) end
return chunk
end

if GenerationCompat.current()~=3 then
local installUI=loadEntryChunk("UIMain.lua")(mod)
if type(installUI)=="function" then installUI(mod) end
end
