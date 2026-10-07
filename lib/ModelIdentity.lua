
local V=...
local M={version=1}
local sourceNames,sourceDexByName=nil,{}
local function sourceDex(species)
if species==nil then return nil end
local names=V.ColosseumDexNames
if type(names)~="table" then return nil end
if names~=sourceNames then
sourceNames=names;sourceDexByName={}
for dex,name in pairs(names) do
if tonumber(dex) and type(name)=="string" then sourceDexByName[name:upper()]=tonumber(dex) end
end
end
return sourceDexByName[tostring(species):upper()]
end
function M.resolve(game,battler)
if type(battler)~="table" then return nil,"Pokemon identity unavailable" end
local mon=type(battler.mon)=="table" and battler.mon or battler
local species=mon.species or mon.id


if V.GenerationCompat and V.GenerationCompat.current()==3 then
local ok,P=pcall(V.engineRequire or require,"src.core.game3.pokemon")
if not ok then return nil,"Gen 3 species provider unavailable" end
local internal=P.speciesOf(mon)
local dex=internal and P.national(internal)
if not dex or not (V.ColosseumDex and V.ColosseumDex.supported(dex)) then
return nil,"No Colosseum model for Gen 3 species "..tostring(internal)
end
local variant=V.ShinySupport.variant(mon)
if dex==351 and battler._cbeCastformForm~=nil then variant=V.ColosseumDex.withForm(variant,battler._cbeCastformForm) end
return dex,variant
end
local defs=game and game.data and game.data.pokemon
local def=defs and (defs[species] or defs[tostring(species)])



local dex=tonumber(def and (def.nationalDex or def.dex or def.number or def.index))
or sourceDex(species)
or tonumber(mon.nationalDex)
or tonumber(mon.speciesIndex)
or tonumber(mon.dex)
if not dex and type(species)=="number" then dex=species end
if not dex and defs and species then
local wanted=tostring(species):upper()
for _,candidate in pairs(defs) do
if type(candidate)=="table" and (tostring(candidate.id):upper()==wanted
or tostring(candidate.name):upper()==wanted) then
dex=tonumber(candidate.nationalDex or candidate.dex or candidate.number or candidate.index);break
end
end
end




local supported=dex and V.ColosseumDex and type(V.ColosseumDex.supported)=="function"
and V.ColosseumDex.supported(dex)
if not dex or dex%1~=0 or dex<1
or (V.ColosseumDex and type(V.ColosseumDex.supported)=="function" and not supported)
or (not V.ColosseumDex and dex>386) then
return nil,"No supported National Dex mapping for "..tostring(species)
end
return dex,V.ShinySupport.variant(battler)
end
return M
