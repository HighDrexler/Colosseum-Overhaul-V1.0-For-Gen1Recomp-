


local V=... or {}
local Catalog=assert(V.ColosseumDexCatalog,"ColosseumDexCatalog dependency required")
local State=assert(V.ColosseumDexState,"ColosseumDexState dependency required")
local Owned=assert(V.ColosseumDexOwnedStorage,"ColosseumDexOwnedStorage dependency required")
local OwnedSidecar=assert(V.ColosseumDexOwnedSidecar,"ColosseumDexOwnedSidecar dependency required")

local R={VERSION=1,MAX_DEX=386}
local cache=setmetatable({},{__mode="k"})

local function registeredSourceDefinitions(pokemon,gen)
local definitions={}
local limit=gen==2 and 251 or 151
for id,def in pairs(pokemon) do
if type(def)=='table' and def.sourceBacked==true
and def.source=='GC6E01 PokemonStats' and tonumber(def.dex)
and def.dex>limit and def.index==nil then
definitions[id]=def
end
end
return definitions
end

local function generation(game,explicit)
local n=tonumber(explicit)
if n==1 or n==2 then return n end
if game and game.data and game.data.gen2Pokedex then return 2 end
local save=game and game.save
if tonumber(save and save.generation)==2 then return 2 end
return 1
end

function R.registry(game,opts)
opts=opts or {}
local data=game and game.data or opts.data
local gen=generation(game,opts.generation or opts.hostGeneration)
local pokemon=data and data.pokemon



if type(pokemon)=="table" and opts.extendedDefinitions==nil then
local entry=cache[pokemon]
if entry and entry[gen] then return entry[gen] end



local reg,err=Catalog.build{hostGeneration=gen,hostPokemon=pokemon,
extendedDefinitions=registeredSourceDefinitions(pokemon,gen)}
if not reg then return nil,err end
entry=entry or {};entry[gen]=reg;cache[pokemon]=entry
return reg
end
return Catalog.build{hostGeneration=gen,hostPokemon=pokemon,
extendedDefinitions=opts.extendedDefinitions}
end

function R.snapshot(game,opts)
opts=opts or {}
local reg,err=R.registry(game,opts);if not reg then return nil,err end
local gen=generation(game,opts.generation or opts.hostGeneration)
return State.snapshot(opts.save or (game and game.save) or {},gen,reg)
end

function R.catalog(game,opts)
opts=opts or {}
local snap,err=R.snapshot(game,opts);if not snap then return nil,err end
local data=game and game.data or opts.data or {}
return State.catalog(snap,opts.mode or "NATIONAL",{
gen2Pokedex=opts.gen2Pokedex or data.gen2Pokedex,
})
end

function R.listItems(game,opts)
local cat,err=R.catalog(game,opts);if not cat then return nil,err end
return State.listItems(cat),cat
end




function R.mark(save,generationValue,registry,identity,kind)
local route,err=State.markRoute(generationValue,registry,identity,kind)
if not route then return nil,err end
if route.route=="native" then return save,nil,route end
return State.markExtended(save,generationValue,registry,identity,kind)
end

function R.prepareOwnedWrite(save,generationValue,registry)
return Owned.prepareWrite(save,generationValue,registry)
end

function R.hydrateOwned(save,generationValue,registry)
return Owned.hydrate(save,generationValue,registry)
end

function R.persistenceStatus()
local bridge=V.ColosseumDexSaveBridge
local status=bridge and bridge.status and bridge.status() or {}
local blocker
if status.ready~=true then blocker=status.blocker or "checked save bridge not installed" end
return {
dexStateBucket=State.BUCKET,ownedBucket=OwnedSidecar.BUCKET,
expandedDexStateSafe=true,automaticOwnedPersistence=status.ready==true,
blocker=blocker,
writes=status.writes or 0,loads=status.loads or 0,lastError=status.lastError,
}
end

R.Identity=V.ColosseumDexIdentity
R.Catalog=Catalog
R.State=State
R.OwnedSidecar=OwnedSidecar
R.OwnedStorage=Owned
return R
