local now=0
love={
  timer={getTime=function() return now end},
  system={getOS=function() return "Windows" end},
}

local warmed={}
local idleBakes={}
local PokemonActors={}
function PokemonActors.informationWarmStatus(game,battler)
  local dex=tonumber(battler and battler.dex) or 1
  return {dex=dex,resident=battler and battler.resident==true,
    cached=battler and battler.cached==true,idlePrepared=battler and battler.idlePrepared==true,supported=true}
end
function PokemonActors.prewarmInformation(game,battler,allowExtract)
  warmed[#warmed+1]={dex=battler.dex,allowExtract=allowExtract==true}
  battler.resident=true
  return true
end
function PokemonActors.bakeInformationIdle(game,battler)
  idleBakes[#idleBakes+1]=battler.dex
  battler.idlePrepared=true
  return true
end
function PokemonActors.hardCacheStatus() return {} end
function PokemonActors.cancelHardCache() end
function PokemonActors.cancelPartyPrewarm() end

local arenaWarms=0
local Arena={}
function Arena.prewarmDefinition(self,ctx,id) arenaWarms=arenaWarms+1 end
local ArenaCatalog={}
function ArenaCatalog.enabled() return true end
function ArenaCatalog.selected() return "outdoor_wild" end

local S=assert(loadfile("lib/ResidentPrewarm.lua"))({
  Arena=Arena,ArenaCatalog=ArenaCatalog,PlayerTrainer=nil,Trainer=nil,
  PokemonActors=PokemonActors,CurrentSpriteModels=nil,WazaHandlers=nil,
  MoveFXExtractor=nil,GeneratedAssets=nil,BattleSettings=nil,
})

-- A generated/cache-backed information model is the only heavy job allowed
-- through while an information viewer lease is active.
local cached={dex=25,cached=true}
local ok,why=S.queueInformation({},cached,"pc")
assert(ok and why=="queued-cached", "cached information model did not queue")
S.touchViewer(0.42,"test")
assert(S.viewerActive()==true,"viewer lease did not activate")
local ran,pending,label=S.pump({})
assert(ran==true and #warmed==1 and warmed[1].dex==25 and warmed[1].allowExtract==false,
  "cached information warm was not allowed through viewer lease")
assert(tostring(label):find("information%-model:pc:25"),"wrong cached viewer job ran")

-- Idle sidecar baking is source/action materialization, not first-pixel work.
-- It must remain deferred even after the cached base has been promoted.
now=0.20
local ranIdle,pendingIdle,labelIdle=S.pump({})
assert(ranIdle==false and #idleBakes==0 and labelIdle=="viewer-defer",
  "information idle sidecar baked while viewer lease was active")
now=0.60
local ranIdle2,pendingIdle2,labelIdle2=S.pump({})
assert(ranIdle2==true and #idleBakes==1 and idleBakes[1]==25,
  "deferred information idle sidecar did not bake after viewer closed")

-- A newer selection on the same surface cancels queued work for the row the
-- user already moved past. Rapid PC/Pokedex scrolling must not upload every
-- intermediate species after the cursor has left it.
S.cancel();warmed={};idleBakes={};now=0.80
local stale={dex=10,cached=true}
local latest={dex=11,cached=true}
assert(S.queueInformation({},stale,"pc"))
assert(S.queueInformation({},latest,"pc"))
S.touchViewer(0.42,"test-prune")
now=0.90
local ranPrune=S.pump({})
assert(ranPrune==true and #warmed==1 and warmed[1].dex==11,
  "superseded PC information warm was not pruned")

-- A selected uncached body now warms cooperatively while the menu is open,
-- rather than leaving a shiny model pod empty until the user closes the viewer.
S.cancel();warmed={};idleBakes={};now=1
local cold={dex=150,cached=false}
ok,why=S.queueInformation({},cold,"pokedex")
assert(ok and why=="queued-source", "cold selected model did not queue")
S.touchViewer(0.42,"test-cold")
now=1.10
local ran2,pending2,label2=S.pump({})
assert(ran2==true and #warmed==1 and warmed[1].dex==150 and warmed[1].allowExtract,
  "selected source model did not progress through viewer lease")

-- Unrelated resident jobs must remain blocked for the entire viewer lease.
S.cancel();now=2;arenaWarms=0
S.queueArena({},"test")
S.touchViewer(0.42,"test-arena")
now=2.20
local ran4,pending4,label4=S.pump({})
assert(ran4==false and arenaWarms==0 and label4=="viewer-defer",
  "unrelated arena prewarm collided with active information viewer")
now=2.60
local ran5=S.pump({})
assert(ran5==true and arenaWarms==1,"deferred arena prewarm did not resume after viewer lease")

print("InformationMenuPerformanceTests: OK")
