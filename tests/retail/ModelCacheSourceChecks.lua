-- Optional user-owned GC6E01 source validation, not the ROM-free test runner.
-- Run from the mod directory with CBE_SOURCE_CISO and CBE_SOURCE_CACHE set.
-- Only generated private files are written there. Never redistribute that cache.
local iso=assert(os.getenv('CBE_SOURCE_CISO'));local output=assert(os.getenv('CBE_SOURCE_CACHE'))
local f=assert(io.open(iso,'rb'));local header=assert(f:read(32768));assert(header:sub(1,4)=='CISO')
local a,b,c,d=header:byte(5,8);local block=a+b*256+c*65536+d*16777216
local offsets={};local n=32768
for i=0,32759 do if header:byte(i+9)==1 then offsets[i]=n;n=n+block end end
local mod={id='source-check',imports={}}
function mod.imports:info()return {size=1459978240}end
function mod.imports:read(id,off,len)
 local out={}
 while len>0 do local i=math.floor(off/block);local at=off%block;local count=math.min(len,block-at)
  if offsets[i] then f:seek('set',offsets[i]+at);out[#out+1]=assert(f:read(count))else out[#out+1]=string.rep('\0',count)end
  off=off+count;len=len-count
 end
 return table.concat(out)
end
local dirs={}
local function mkdir(p)
 if dirs[p] then return end
 local ok=os.execute("mkdir -p '"..p:gsub("'","'\"'\"'").."'");assert(ok==0 or ok==true);dirs[p]=true
end
mod.cache={}
function mod.cache:read(p)local h=io.open(output..'/'..p,'rb');if not h then return nil end;local s=h:read('*a');h:close();return s end
function mod.cache:write(p,s)mkdir(output..'/'..p:match('(.+)/'));local h=assert(io.open(output..'/'..p,'wb'));h:write(s);h:close();return true end
function mod.cache:info(p)local h=io.open(output..'/'..p,'rb');if not h then return nil end;local n=h:seek('end');h:close();return {type='file',size=n}end
function mod.cache:delete(p)return os.remove(output..'/'..p)end
function mod:read(p)local h=io.open(p,'rb');if not h then return nil end;local s=h:read('*a');h:close();return s end
local function loadM(p,v)return assert(loadfile(p))(v)end
local H=loadM('tests/support/ShinyHarness.lua');local h=H.new({disk=true}) -- graphics ONLY are mocked
local V={mod=mod,Mat4=loadM('lib/Mat4.lua'),ColosseumDex=loadM('lib/ColosseumDex.lua'),ShinySupport=loadM('lib/ShinySupport.lua')}
V.GeneratedAssets=loadM('lib/GeneratedAssets.lua',V);V.RuntimeMeshCache=loadM('lib/RuntimeMeshCache.lua',V)
V.WorkBudget=loadM('lib/WorkBudget.lua',V);love.timer.getTime=os.clock
local disc=loadM('extract/GameCubeDisc.lua').open(mod);local FSYS=loadM('extract/FSYS.lua')
local GX=loadM('extract/GXTexture.lua');local HSD=loadM('extract/HSD.lua',{GXTexture=GX})
local Meta=loadM('extract/PKXMetadata.lua',{FSYS=FSYS,ColosseumDex=V.ColosseumDex,ShinySupport=V.ShinySupport})
local E=loadM('extract/PokemonExtractor.lua',{HSD=HSD,FSYS=FSYS,ColosseumDex=V.ColosseumDex,PKXMetadata=Meta,ShinySupport=V.ShinySupport})
local A=loadM('lib/PokemonActors.lua',V);V.PokemonActors=A
local opens=0;A.install(E,function()opens=opens+1;return disc end,nil,Meta)
-- All 502 colour identities must map to a real archive plus valid source recipe.
local units,filters=0,0
for dex=1,251 do
 for _,variant in ipairs{'normal','shiny'} do
  if variant=='normal' or V.ColosseumDex.rare[dex] then
   local archive=V.ColosseumDex.archive(dex,variant);assert(disc:file(archive),'missing '..archive)
   local metadata,why=Meta.inspectSpecies(disc,dex,variant);assert(metadata,why)
   if not V.ColosseumDex.rare[dex] then assert(V.ShinySupport.validFilter(metadata.shinyFilter),'filter '..dex);filters=filters+1 end
   units=units+1
  end
 end
 if dex%25==0 then print('SOURCE METADATA',dex,units);io.stdout:flush()end
end
assert(units==270 and filters==232);print('PASS 502 appearance routes: 270 real source archives / 232 source colour recipes');io.stdout:flush()
local tested={{100,'normal'},{156,'normal'},{246,'shiny'},{6,'shiny'}}
for _,row in ipairs(tested)do
 local start=os.clock();local task=V.WorkBudget.new(function()return A.prepareSessionModel(row[1],row[2])end)
 local slices=0
 while true do
  local ok,state,value,why=V.WorkBudget.resume(task,6);slices=slices+1;assert(ok,state)
  if state=='done' then assert(value,why);break end
 end
 print(('PREPARED %d %s cpu=%.3f slices=%d'):format(row[1],row[2],os.clock()-start,slices));io.stdout:flush()
 local actor,err=A.acquireCached('selected',row[1],row[2],{context={services={informationSurface=true}}})
 assert(actor,err);assert(actor.variant==row[2]);actor:release()
end
local before=opens
for _,row in ipairs(tested)do assert(A.prepareSessionModel(row[1],row[2]))end
assert(opens==before,'warm request reopened source')
print('PASS final source preparation + exact actor variants + warm reuse (graphics mocked)')
