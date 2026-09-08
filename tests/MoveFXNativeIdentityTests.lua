local W={revision=12}
local E=assert(loadfile('extract/MoveFXExtractor.lua'))({WazaSequenceExtractor=W})
local files={};local rows={}
for id=1,251 do
 local stem='cachedsource'..id
 rows[#rows+1]=(' [%d]={stem=%q},'):format(id,stem)
 files[E.cachePath(stem)]=('return {revision=%d,wazaRevision=12,stem=%q,moveId=%d}'):format(E.revision,stem,id)
end
files['cache/movefx/index.lua']='return {moves={'..table.concat(rows)..'}}'
local reads=0
E.install({cache={read=function(_,p)reads=reads+1;return files[p]end}},function()error('Runtime lookup must not open ISO')end)
for _,row in ipairs({{58,'ICE_BEAM','ICE BEAM'},{56,'HYDRO_PUMP','HYDRO PUMP'}})do
 E.memory={};E.indexMemory=nil;E.sourceMoveRows=nil
 local spec=E.peek(row[2],{id=row[2],index=row[1],name=row[3]})
 assert(spec and spec.moveId==row[1],'Native identifier failed: '..row[2])
end
for id=1,251 do
 E.memory={};E.indexMemory=nil;E.sourceMoveRows=nil
 local spec=E.peek('NATIVE_'..id,{id='NATIVE_'..id,index=id,name='localized name'})
 assert(spec and spec.moveId==id,'Native move index failed: '..id)
end
local stem='ballnormalopen'
files[E.cachePath(stem)]=('return {revision=%d,wazaRevision=12,stem=%q}'):format(E.revision,stem)
assert(E.peek(nil,{name=stem}).stem==stem,'Exact-stem release lookup changed')
assert(not E.peek('UNKNOWN',{name='UNKNOWN'}),'Unknown move borrowed an effect')
print('MoveFXNativeIdentityTests: 251 cold-cache native indices, named Ice Beam/Hydro Pump, exact stem and unknown move OK')
