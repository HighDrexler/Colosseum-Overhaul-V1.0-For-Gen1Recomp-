local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local D=assert(loadfile('lib/ColosseumDex.lua'))();local S=assert(loadfile('lib/ShinySupport.lua'))()
local E=assert(loadfile('extract/PokemonExtractor.lua'))({HSD={},FSYS={},ColosseumDex=D,ShinySupport=S})
local files={};local mod={cache={info=function(_,path)if files[path] then return {type='file',size=#files[path]}end end,read=function(_,path)return files[path]end}}
for dex=1,251 do
 local normal,shiny=E.cachePath(dex,'normal'),E.cachePath(dex,'shiny')
 files[normal]='fixture';files[E.revPath(dex)]=E.stamp({})
 yes(E.isCached(mod,dex),'legacy normal revision reusable')
 if D.rare[dex] then
  yes(not E.isCached(mod,dex,{variant='shiny'}),'rare cannot borrow normal stamp')
  files[shiny]='rare-fixture';files[E.revPath(dex,'shiny')]=E.stamp({})
  yes(E.isCached(mod,dex,{variant='shiny'}),'rare stamp recognized')
  yes(E.cachePath(tostring(dex)..':shiny')==shiny,'composite key maps to same source root')
 else yes(normal==shiny and E.isCached(mod,dex,{variant='shiny'}),'shared source available, material read separately')end
end
-- Source metadata access selects the authored variant archive and carries the
-- cooperative decompression callback through the real inspectSpecies function.
local function u32(n)return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256)end
local blob=u32(32)..u32(0)..u32(1)..string.rep('\0',52)..u32(32)..string.rep('\0',28)..string.rep('\0',208)
 ..u32(2)..u32(1)..u32(0)..u32(3)..string.char(127,127,127,127)
local opened,progress={},0
local arc={modelEntries=function()return {{name='fixture.pkx'}}end,list=function()return {}end,
 extract=function(_,entry,opts)yes(type(opts.progress)=='function','metadata progress forwarded');opts.progress();return blob end}
local P=assert(loadfile('extract/PKXMetadata.lua'))({ColosseumDex=D,ShinySupport=S,FSYS={open=function()return arc end}})
local disc={file=function(_,path)opened[#opened+1]=path;return {}end}
local m=assert(P.inspectSpecies(disc,6,'shiny',nil,{progress=function()progress=progress+1 end}))
yes(opened[1]=='pkx_rare_lizardon.fsys' and progress==1,'separate shiny metadata source')
yes(m.shinyFilter~=nil,'native parameters retained')
local n=assert(P.inspectSpecies(disc,25,'shiny',nil,{progress=function()progress=progress+1 end}))
yes(opened[2]=='pkx_pikachu.fsys','native-filter source uses ordinary archive')
-- Exercise the actual manifest writer (an upvalue, not a duplicate algorithm).
local record=E._test and E._test.recordManifest
for i=1,100 do local name,value=debug.getupvalue(E.extractSpecies,i);if not name then break end;if name=='recordManifest' then record=value end end
assert(record,'manifest writer missing')
local stored={};local disk={cache={read=function(_,p)return stored[p]end,write=function(_,p,s)stored[p]=s;return true end}}
record(disk,6,'lizardon',{'cache/pokemon/6/model_cache.lua'},'normal')
record(disk,6,'rare_lizardon',{'cache/pokemon/6/shiny/model_cache.lua'},'shiny')
record(disk,6,'lizardon',{'cache/pokemon/6/rev.txt'},'normal')
local manifest=assert(load(stored[E.MANIFEST]))()
yes(#manifest==2,'manifest variants coexist across normal refresh')
local found={};for _,row in ipairs(manifest)do found[row.variant]=row.paths[1]end
yes(found.shiny=='cache/pokemon/6/shiny/model_cache.lua' and found.normal=='cache/pokemon/6/rev.txt','manifest preserves exact variant paths')
print('ShinyExtractorContractTests: '..checks..' checks passed; cache paths and synthetic metadata/source reader')
