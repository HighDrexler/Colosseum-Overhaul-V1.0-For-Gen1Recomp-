local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function near(a,b,label)check(math.abs(a-b)<1e-6,label..': '..tostring(a)..' vs '..tostring(b))end
local decodes=0
local H=assert(loadfile('extract/HSD.lua'))({GXTexture={dataSize=function()return 4 end,decode=function()decodes=decodes+1;return '\255\255\255\255'end}})
local apply=H._test.applySourceTextureState
local function texture(extra)
 local t={coordinateMode=0,texgen=4,scale={1,1,1},rotation={0,0,0},translation={0,0,0},repeatS=1,repeatT=1,wrapT=0}
 for k,v in pairs(extra or {})do t[k]=v end;return t
end
local function rows()return {{1,2,3,.125,.25,.2,.3,.4,.5,0,1,0}}end
local original=rows()[1];local v=rows()
check(apply(v,texture({translation={-.5,-.5,0}}),true),'ordinary UV stage rejected')
near(v[1][4],.625,'Water spectator atlas U quadrant');near(v[1][5],.75,'Water spectator atlas V quadrant')
for k=1,12 do if k~=4 and k~=5 then near(v[1][k],original[k],'UV bake changed geometry/color/normal channel '..k)end end
v=rows();apply(v,texture({scale={.5,2,1},repeatS=2,repeatT=3,translation={.1,-.5,0}}),true)
near(v[1][4],.1,'inverse scale and repeat U');near(v[1][5],1.125,'inverse scale and repeat V')
v=rows();apply(v,texture({rotation={0,0,math.pi/2},translation={.125,0,0}}),true)
near(v[1][4],.25,'native clockwise texture rotation');near(v[1][5],0,'translation must precede rotation')
v=rows();apply(v,texture({wrapT=2,scale={1,2,1},repeatT=3,translation={0,-.5,0}}),true)
near(v[1][5],.125,'mirror-T native phase')
v=rows();apply(v,texture({scale={0,1,1}}),true);near(v[1][4],0,'zero source U scale must remain finite')
for _,case in ipairs({{texture({translation={-.5,0,0}}),false},{texture({coordinateMode=1}),true},{texture({texgen=0}),true},{texture({rotation={.2,0,0}}),true},{texture({repeatT=0}),true}})do
 v=rows();check(not apply(v,case[1],case[2]),'unsupported/disabled stage was baked');near(v[1][4],.125,'preserve actor/reflection/projected U');near(v[1][5],.25,'preserve actor/reflection/projected V')
end
-- Binary TOBJ descriptors sharing one GX image retain distinct source state.
local bytes={};for i=1,640 do bytes[i]='\0'end
local function put(off,s)for i=1,#s do bytes[off+i]=s:sub(i,i)end end
local function u32(off,n)put(off,string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256))end
local function f32(off,n)put(off,string.pack('<f',n):reverse())end
local function descriptor(p,flags,blend,tx)
 u32(p+0x0C,4);for k=0,2 do f32(p+0x10+k*4,0);f32(p+0x1C+k*4,1);f32(p+0x28+k*4,k==0 and tx or 0)end
 u32(p+0x34,1);u32(p+0x38,2);put(p+0x3C,string.char(2,3));u32(p+0x40,flags);f32(p+0x44,blend)
end
descriptor(32,0x00330010,.375,-.5);descriptor(320,0x00340010,1,0)
put(164,'\0\1\0\1');u32(168,0)
local pointers={[32+0x4C]=160,[320+0x4C]=160,[160]=256}
local archive={blob=table.concat(bytes),base=0,fileSize=640,data=0,ptr=function(_,p)return pointers[p]end}
local t=H._test.decodeTextureObject(archive,32,0,true);local other=H._test.decodeTextureObject(archive,320,1,true)
local actor=H._test.decodeTextureObject(archive,32,0)
check(actor.colorMap==nil and actor.translation==nil and actor.rgba==t.rgba,'actor texture path gained static arena state')
check(t and other and t.w==1 and t.h==1,'binary texture fixture did not decode')
check(decodes==1 and t.rgba==other.rgba,'shared atlas was decoded per material')
check(t.colorMap==3 and other.colorMap==4 and t.alphaMap==3,'native color/alpha stage masks')
check(t.coordinateMode==0 and t.texgen==4 and t.repeatS==2 and t.repeatT==3,'TOBJ coordinate and repeat offsets')
near(t.blending,.375,'TOBJ blending offset');near(t.translation[1],-.5,'TOBJ translation offset')
-- Exercise canonical source serialization and binary sidecar metadata together.
local writes={};local fixture={textureStateVersion=1,groups={{texture=t,vertices={{0,0,0,0,0,0,1,0},{1,0,0,1,0,0,1,0},{0,0,1,0,1,0,1,0}},renderFlags=0x14,useDiffuseLighting=true}},vertexCount=3,bounds={min={0,0,0},max={1,0,1}},sceneRoots=1}
local B=assert(loadfile('extract/ArenaBuilder.lua'))({HSD={extractSceneModel=function(_,opts)check(opts.sourceTextureState==true,'static arena did not request TOBJ state');return fixture end},FSYS={open=function()return {member=function()return {name='fixture.dat',modelKind=true}end,extract=function()return 'fixture'end}end}})
local spec={id='relic_chamber',cache='cache/fixture.lua',sourceFsys='fixture.fsys',sourceMember='fixture.dat',textureRoot='cache/fixture',minVertices=1,minGroups=1}
local mod={cache={write=function(_,path,data)writes[path]=data;return true end,read=function(_,path)return writes[path]end}}
B._test.buildSourceArena(mod,{file=function()return {}end},function()end,{},spec)
local cache=assert(load(writes[spec.cache]))()
check(cache.textureStateVersion==1,'canonical texture state marker lost')
local ct=cache.groups[1].texture
check(ct.colorMap==3 and ct.alphaMap==3 and ct.coordinateMode==0,'canonical texture material metadata lost')
near(ct.blending,.375,'canonical texture blend changed');check(ct.wrapS==1 and ct.wrapT==2,'source sampler changed')
local oldLove=love;love={data={pack=function(_,fmt,...)return string.pack(fmt,...)end}}
B._test.writeRuntimeSidecar(mod,spec,cache,#writes[spec.cache],{},nil,'fixture-fingerprint')
love=oldLove
local meta=assert(load(writes['cache/runtime_mesh_v7/arenas/relic_chamber/scene.lua']))()
check(meta.textureStateVersion==1 and meta.sourceFingerprint=='fixture-fingerprint','sidecar source identity lost')
local rt=assert(meta.opaque[1],'fixture opaque mesh missing').texture
check(rt.colorMap==3 and rt.alphaMap==3 and rt.coordinateMode==0,'sidecar texture stage lost');near(rt.blending,.375,'sidecar texture blend changed')
print('PresentationFidelitySweepTextureStateTests: '..checks..' assertions passed')
return true
