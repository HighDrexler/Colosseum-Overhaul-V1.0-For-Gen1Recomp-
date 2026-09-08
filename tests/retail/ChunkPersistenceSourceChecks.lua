-- Optional actual-source persistence check in TWO SEPARATE PROCESSES.
-- Use a private diagnostic directory, never a live cache. Do not distribute it.
-- CBE_CACHE_CHECK_PHASE=cold|warm, CBE_SOURCE_CACHE=/private/path;
-- cold also needs CBE_SOURCE_CISO=/path/to/the/user/source.ciso.
local phase=os.getenv('CBE_CACHE_CHECK_PHASE')or 'warm'
local output=assert(os.getenv('CBE_SOURCE_CACHE'))
local function M(p,v)return assert(loadfile(p))(v)end
local dirs={};local writes,writeBytes,reads,readBytes,opens=0,0,0,0,0
local function mkdir(p)
 if dirs[p]then return end
 local ok=os.execute("mkdir -p '"..p:gsub("'","'\"'\"'").."'");assert(ok==0 or ok==true);dirs[p]=true
end
local mod={id='private-source-check',cache={}}
function mod.cache:read(p)local f=io.open(output..'/'..p,'rb');if not f then return nil end;local b=f:read('*a');f:close();reads=reads+1;readBytes=readBytes+#b;return b end
function mod.cache:write(p,b)
 assert(phase=='cold','WARM RESTART ATTEMPTED A CACHE WRITE: '..p)
 mkdir(output..'/'..p:match('(.+)/'));local f=assert(io.open(output..'/'..p,'wb'));assert(f:write(b));f:close()
 writes=writes+1;writeBytes=writeBytes+#b;return true
end
function mod.cache:info(p)local f=io.open(output..'/'..p,'rb');if not f then return nil end;local n=f:seek('end');f:close();return {type='file',size=n}end
function mod.cache:delete(p)error('unexpected deletion '..p)end
local function fileRead(p)local f=io.open(p,'rb');if not f then return nil end;local b=f:read('*a');f:close();return b end
function mod:read(p)return fileRead(p)end
local H=M('tests/support/ShinyHarness.lua');H.new({disk=true}) -- graphics doubles only
love.timer.getTime=os.clock
local V={mod=mod,Mat4=M('lib/Mat4.lua'),ColosseumDex=M('lib/ColosseumDex.lua'),ShinySupport=M('lib/ShinySupport.lua')}
V.WorkBudget=M('lib/WorkBudget.lua');V.GeneratedAssets=M('lib/GeneratedAssets.lua',V);V.RuntimeMeshCache=M('lib/RuntimeMeshCache.lua',V)
local FSYS=M('extract/FSYS.lua');local GX=M('extract/GXTexture.lua');local HSD=M('extract/HSD.lua',{GXTexture=GX})
local Meta=M('extract/PKXMetadata.lua',{FSYS=FSYS,ColosseumDex=V.ColosseumDex,ShinySupport=V.ShinySupport})
local E=M('extract/PokemonExtractor.lua',{HSD=HSD,FSYS=FSYS,ColosseumDex=V.ColosseumDex,PKXMetadata=Meta,ShinySupport=V.ShinySupport})
local disc,source
if phase=='cold'then
 source=assert(io.open(assert(os.getenv('CBE_SOURCE_CISO')),'rb'))
 local h=assert(source:read(32768));assert(h:sub(1,4)=='CISO');local a,b,c,d=h:byte(5,8);local block=a+b*256+c*65536+d*16777216
 local offsets,offset={},32768;for i=0,32759 do if h:byte(i+9)==1 then offsets[i]=offset;offset=offset+block end end
 mod.imports={info=function()return {size=1459978240}end}
 function mod.imports:read(_,off,len)
  local out={};while len>0 do local i=math.floor(off/block);local at=off%block;local n=math.min(len,block-at)
   if offsets[i]then source:seek('set',offsets[i]+at);out[#out+1]=assert(source:read(n))else out[#out+1]=string.rep('\0',n)end
   off=off+n;len=len-n
  end;return table.concat(out)
 end
 disc=M('extract/GameCubeDisc.lua').open(mod)
end
local A=M('lib/PokemonActors.lua',V)
A.install(E,function()opens=opens+1;assert(disc,'WARM RESTART ATTEMPTED SOURCE ACCESS');return disc end,nil,Meta)
local rows={{100,'normal'},{25,'shiny'},{157,'shiny'}}
for _,row in ipairs(rows)do
 local start=os.clock();local w0=writeBytes
 if phase=='warm' then assert(A.persistentModelState(row[1],row[2]),'completed model not recognized')end
 local task=V.WorkBudget.new(function()return A.prepareSessionModel(row[1],row[2])end)
 local slices=0
 repeat local ok,state,value,why=V.WorkBudget.resume(task,12);assert(ok,state);slices=slices+1
  if state=='done'then assert(value,why);break end
 until false
 assert(A.persistentModelState(row[1],row[2]),'unit not persisted')
 local actor,why=A.acquireCached('selected',row[1],row[2],{context={services={informationSurface=true}}})
 assert(actor,why);assert(actor.variant==row[2]);actor:release()
 print(('%s dex=%d variant=%s cpu=%.3f slices=%d bytesWritten=%d'):format(phase,row[1],row[2],os.clock()-start,slices,writeBytes-w0));io.stdout:flush()
end
if phase=='warm'then
 assert(writes==0 and opens==0,'repeat work during warm startup')
 assert(A.prepareSessionModel(25,'normal'));assert(A.prepareSessionModel(100,'shiny'))
 assert(writes==0 and opens==0,'shared-body counterpart repeated work')
end
print(('PASS %s writes=%d bytes=%d sourceOpens=%d cacheReads=%d readBytes=%d; graphics mocked'):format(phase,writes,writeBytes,opens,reads,readBytes))
if source then source:close()end
