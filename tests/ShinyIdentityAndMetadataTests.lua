local S=assert(loadfile('lib/ShinySupport.lua'))();local D=assert(loadfile('lib/ColosseumDex.lua'))()
local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local function near(x,y,k)yes(math.abs(x-y)<1e-9,k)end
local dvs={attack=10,defense=10,speed=10,special=10}
yes(S.isShiny({dvs=dvs}),'DV-only shiny')
yes(S.isShiny({mon={pokemon={dvs=dvs}}}),'nested shiny')
yes(not S.isShiny({shiny=false,dvs=dvs}),'resolved false is authoritative')
yes(S.isShiny({shiny=true,dvs={}}),'explicit shiny does not reroll')
yes(S.isShiny({isShiny=true}),'custom explicit flag')
yes(not S.isShiny({ivs=dvs}),'IVs are not Gen II DVs')
yes(not S.isShiny(nil),'nil safe')
local cycle={};cycle.mon=cycle;yes(not S.isShiny(cycle),'cycle safe')
local accepted={[2]=true,[3]=true,[6]=true,[7]=true,[10]=true,[11]=true,[14]=true,[15]=true}
for a=0,15 do local mon={dvs={attack=a,defense=10,speed=10,special=10}}
 yes(S.isShiny(mon)==not not accepted[a],'attack DV '..a);yes(mon.shiny==nil,'identity is read-only')
 for _,key in ipairs{'defense','speed','special'}do mon.dvs[key]=9;yes(not S.isShiny(mon),'required DV '..key);mon.dvs[key]=10 end
end
local function u32(n)return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256)end
-- Synthetic structurally valid Colosseum container: header40 DAT20 slotD0 tail14.
local header=u32(32)..u32(0)..u32(1)..string.rep('\0',52)
local dat=u32(32)..string.rep('\0',28)
local slot=string.rep('\0',208)
local tail=u32(2)..u32(0)..u32(3)..u32(3)..string.char(77,0,127,255)
local blob=header..dat..slot..tail
local f=S.parseFilter(blob,#header+#dat+#slot)
yes(f~=nil,'tail parsed outside animation metadata');yes(f.route[1]==2 and f.route[3]==3,'big-endian routing')
yes(f.rawARGB[1]==77 and f.rawARGB[2]==0 and f.rawARGB[4]==255,'ARGB byte order')
near(f.gain[1],0,'zero brightness');near(f.gain[2],1,'neutral127');near(f.gain[3],2,'full255')
local out=S.apply(f,{.2,.3,.4,.6});near(out[1],0,'route/gain');near(out[2],.2,'route before light');near(out[3],1,'clamp RGB');near(out[4],.6,'alpha unchanged')
yes(not S.parseFilter(blob,#blob-19),'tail cannot overlap slot');yes(not S.parseFilter(blob:sub(1,-21),#header+#dat+#slot),'truncated missing tail')
yes(not S.parseFilter(header..dat..slot..u32(9)..tail:sub(5),#header+#dat+#slot),'invalid routing rejected')
local cached=assert(load('return {'..S.filterField(f)..'}'))();yes(S.validFilter(cached.shinyFilter),'serialization survives relaunch')
local P=assert(loadfile('extract/PKXMetadata.lua'))({FSYS={},ColosseumDex=D,ShinySupport=S})
local metadata=assert(P.parse(blob));yes(S.validFilter(metadata.shinyFilter),'real metadata parser carries recipe')
local old=assert(P.parse(blob:sub(1,-21)));yes(old.shinyFilter==nil,'old metadata stays valid, no invented recipe')
local rare=0
for dex=1,251 do
 yes(D.supported(dex),'all supported dex')
 local n,r=D.modelKey(dex,'normal'),D.modelKey(dex,'shiny')
 if D.rare[dex] then
  rare=rare+1;yes(n~=r,'rare source separated');yes(D.archive(r):find('pkx_rare_',1,true)==1,'rare archive')
  yes(D.cacheRoot(r)==D.cacheRoot(n)..'/shiny','rare disk root')
 else yes(n==r,'shared geometry');yes(D.archive(dex,'shiny')==D.archive(dex,'normal'),'native-filter source')end
 yes(D.number(r)==dex,'variant key number');yes(D.modelKey(r)==r,'variant key roundtrip')
end
yes(rare==19,'19 separate-model species, remaining232 native recipes')
for r=0,3 do for g=0,3 do for b=0,3 do
 local q={route={r,g,b},gain={1,1,1}};local c={.12,.24,.36,.48};local result=S.apply(q,c);local rows=S.uniforms(q)
 for i=1,3 do near(result[i],c[q.route[i]+1],'64 routing combinations');near(rows[i][q.route[i]+1],1,'shader one-hot route')end
 near(result[4],c[4],'all routes preserve alpha')
end end end
print('ShinyIdentityAndMetadataTests: '..checks..' checks passed; synthetic PKX only')
