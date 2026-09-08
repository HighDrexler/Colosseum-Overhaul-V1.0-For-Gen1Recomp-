-- New integration contracts, runnable in LuaJIT without ROM or GPU.
local n=0
local function eq(a,b,label)n=n+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,label)n=n+1;assert(math.abs(a-b)<1e-6,label)end
local function read(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local I=assert(loadfile('lib/ArenaCacheIdentity.lua'))()
local C=assert(loadfile('lib/ArenaAudienceProfile.lua'))()
local B=assert(loadfile('extract/ArenaBuilder.lua'))({ArenaCacheIdentity=I,ArenaAudienceProfile=C})
local R=assert(loadfile('lib/Arena.lua'))({ArenaAudienceProfile=C})
local S=assert(loadfile('lib/BattleSettings.lua'))()
local game={save={colosseumBattle={arena='cipher_lab_underground'}}}
eq(S.prefs(game).arena,'cipher_lab_underground','lab selection survives normalization')
eq(S.prefs(game).doubleBattlesEnabled,true,'release doubles default ON')
local canonical=B._test.arenas;eq(#canonical,11,'canonical arena count')
local lab;for _,a in ipairs(canonical)do if a.id=='cipher_lab_underground' then lab=a end end
assert(lab,'lab extractor registered');eq(lab.sourceFsys,'D1_labo_B1_bf.fsys','source archive');eq(lab.sourceMember,'D1_labo_B1_bf.dat','source battle room')
local H=assert(loadfile('extract/HSD.lua'))({})._test
for _,case in ipairs({
 {0,string.char(255,255),{1,1,1,1}},
 {1,string.char(0,128,255),{0,128/255,1,1}},
 {2,string.char(0,128,255,0),{0,128/255,1,1}},
 {3,string.char(0xf8,0x40),{1,136/255,68/255,0}},
 {4,string.char(255,255,255),{1,1,1,1}},
 {5,string.char(12,89,231,110),{12/255,89/255,231/255,110/255}}
})do
 local c,pos=H.packedVertexColor(case[2],1,case[1]);eq(pos,#case[2]+1,'packed color stride')
 for i=1,4 do near(c[i],case[3][i],'packed component')end
end
eq(H.packedVertexColor('\255',1,5),nil,'truncated packed color rejected')
local vertices={{1,0,0,0,0,.2,.4,.7,.5,0,2,0},{2,0,0,1,0,.3,.5,.9,.6,0,2,0},{1,0,1,0,1,.4,.6,.8,.7,0,2,0}}
for _,mode in ipairs({0,4})do
 local out=B._test.runtimeWithNormals(vertices,mode,1000)
 local direct=R._test.withNormals(vertices,mode,1000)
 eq(#out,3,'triangle count unchanged');eq(#direct,3,'direct triangle count')
 for i,v in ipairs(vertices)do
  eq(#out[i],12,'GPU row remains 48 bytes')
  for j=1,9 do near(out[i][j],v[j],'source position UV color alpha retained')end
  for j=1,12 do near(out[i][j],direct[i][j],'packed/direct renderer agrees')end
  local len=math.sqrt(out[i][10]^2+out[i][11]^2+out[i][12]^2)
  near(out[i][11]/len,1,'authored normal direction')
  if mode==0 then near(len,1,'ordinary normal normalized')else assert(len>=1 and len<2,'crowd phase range')end
 end
end
local venues={water={'water/source',0x0d5b60},orre_colosseum={'orre/source',0x10f240},pyrite_colosseum={'pyrite/source',0x103580},deep_colosseum={'deep/source',0x09d8c0},realgam_colosseum={'realgam/source',0x0bed60},mt_battle_summit={'d2_crater/textures',0x106ee0}}
for id,d in pairs(venues)do
 local path=('cache/stages/%s/tex_%06x_128x128_f14.rgba'):format(d[1],d[2])
 eq(C.classifySourceTexture(id,path)~=nil,true,'source crowd recognized '..id)
 eq(B._test.runtimeMaterialMode({texture={path=path}},true,id),4,'dedicated crowd material '..id)
 for other in pairs(venues)do if other~=id then eq(C.classifySourceTexture(other,path),nil,'no cross-arena offset collision')end end
end
local one=I.fingerprint('return {value=1}');local two=I.fingerprint('return {value=2}')
eq(one==two,false,'same-size content change detected')
local mod={cache={info=function()return {type='file',size=144}end}}
local meta={runtimeMeshVersion=7,sourceSize=16,sourceCache='cache/test.lua',sourceFingerprint=one,opaque={{runtimeBin='mock.f32'}},cutout={},crowd={},translucent={},additive={}}
eq(B._test.runtimeUsable(mod,meta,{cache='cache/test.lua'},16,one),true,'matching content accepted')
eq(B._test.runtimeUsable(mod,meta,{cache='cache/test.lua'},16,two),false,'same-size stale content rejected')
meta.runtimeMeshVersion=6;eq(B._test.runtimeUsable(mod,meta,{cache='cache/test.lua'},16,one),false,'legacy packing rejected')
eq(R._test.vertex,R._test.mobileVertex,'mobile shares crowd/water/lava/foliage motion')
assert(R._test.pixel:find('mix(1.0,tint.a,step(0.5,sourceVertexAlpha))',1,true),'vertex alpha uses separate transparency gate, not RGB flag')
assert(read('extract/BuildPipeline.lua'):find('local B={cacheVersion=2,extractorRevision=15}',1,true),'global cache epoch changed')
print('ArenaSourceIntegrationTests: '..n..' assertions passed')
