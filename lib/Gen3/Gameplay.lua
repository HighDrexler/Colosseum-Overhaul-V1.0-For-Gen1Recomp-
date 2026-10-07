local V=...
local req=V.engineRequire or require
local G={installed=false,replaced=0,pools={}}
local excluded={[144]=true,[145]=true,[146]=true,[150]=true,[151]=true,[243]=true,[244]=true,[245]=true,
[249]=true,[250]=true,[251]=true,[377]=true,[378]=true,[379]=true,[380]=true,[381]=true,[382]=true,[383]=true,[384]=true,[385]=true,[386]=true}
function G.replace(enc,ctx)
if not enc or enc.roamer or enc.foe or V.Gen3Runtime.prefs().expandedWild==false then return enc end
local rng=ctx and ctx.rng or req('src.core.game3.rng').Random
if V.Gen3Runtime.prefs().wildSpawnMode~='new_only' and rng()%2==0 then return enc end
local P=req('src.core.game3.pokemon')
local water=ctx and ctx.terrain=='water'
local key=water and 'water' or 'land'
local pool=G.pools[key]
if not pool then
pool={};G.pools[key]=pool
for dex=152,386 do
local sp=P.speciesFromNational(dex)
if sp and not excluded[dex] then
local types=P.types(sp)
local aquatic=types and (types[1]==11 or types[2]==11)
if (water and aquatic) or (not water and not aquatic) then pool[#pool+1]=sp end
end
end
end
if #pool==0 then return enc end
local out={};for k,v in pairs(enc) do out[k]=v end
local sp=pool[rng()%#pool+1]
out.species=P.keyName(sp);out.speciesId=sp
G.replaced=G.replaced+1
return out
end
function G.install()
if G.installed then return end
V.mod.hooks:wrap('encounter.species',function(next,enc,ctx) return G.replace(next(enc,ctx),ctx) end,115)
V.mod.exports.colosseumDexSpawns=function()
local p=V.Gen3Runtime.prefs()
return {active=G.installed and p.expandedWild~=false,generation=3,replaced=G.replaced,
mode=p.expandedWild==false and 'native' or p.wildSpawnMode=='new_only' and 'native-gen3-expanded-only' or 'native-gen3-50-percent-expansion'}
end
G.installed=true
end
return G
