local AbilityData=assert(loadfile('lib/AbilityData.lua'))()

local speciesCount=0
for dex=1,251 do
 local ids=AbilityData.bySpecies[dex]
 assert(type(ids)=='table' and #ids>=1,'missing ability for dex '..dex)
 speciesCount=speciesCount+1
 for _,id in ipairs(ids) do
  assert(AbilityData.byId[id],'unknown ability id '..tostring(id)..' referenced by dex '..dex)
 end
end
assert(speciesCount==251,'expected 251 species, got '..speciesCount)

local dualCount,singleCount=0,0
for dex=1,251 do
 local n=#AbilityData.bySpecies[dex]
 if n==2 then dualCount=dualCount+1
 elseif n==1 then singleCount=singleCount+1
 else error('species '..dex..' has '..n..' ability slots') end
end
assert(dualCount+singleCount==251,'unexpected slot counts')
assert(dualCount>0,'expected some dual-ability species')

local abilityCount=0
for _ in pairs(AbilityData.byId) do abilityCount=abilityCount+1 end
assert(abilityCount==62,'expected 62 abilities, got '..abilityCount)

for id,meta in pairs(AbilityData.byId) do
 assert(type(meta.display)=='string' and #meta.display>0,'ability '..id..' missing display name')
 assert(type(meta.category)=='string' and #meta.category>0,'ability '..id..' missing category')
end

local contactCount=0
for _ in pairs(AbilityData.contactMoves) do contactCount=contactCount+1 end
assert(contactCount>0,'contact move table is empty')

print(('AbilityDataTests: %d species (%d dual, %d single), %d abilities, %d contact moves OK')
  :format(speciesCount,dualCount,singleCount,abilityCount,contactCount))
