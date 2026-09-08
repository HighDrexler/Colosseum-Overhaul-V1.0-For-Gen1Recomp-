local H=assert(loadfile('extract/HSD.lua'))({})
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function near(a,b,label)check(math.abs(a-b)<1e-5,label..': '..tostring(a)..' vs '..tostring(b))end
-- Synthetic HSD archive: two instances share a target with a nonidentity root
-- SRT. The target also has a normally owned sibling, which must never become
-- part of either instance. Real GX display bytes exercise the production walk.
local bytes={};for i=1,2048 do bytes[i]='\0'end
local function put(off,s)for i=1,#s do bytes[off+i]=s:sub(i,i)end end
local function u32(off,n)put(off,string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256))end
local function u16(off,n)put(off,string.char(math.floor(n/256)%256,n%256))end
local function f32(off,n)put(off,string.pack('<f',n):reverse())end
local pointers={}
local function ptr(off,p)pointers[off]=p end
local function joint(p,flags,tx,ty,ry)
 u32(p+4,flags);for k=0,2 do f32(p+0x20+k*4,1)end
 f32(p+0x18,ry or 0);f32(p+0x2C,tx or 0);f32(p+0x30,ty or 0)
end
joint(64,0x40000000);joint(128,0x40001000,0,10,math.pi/2);joint(192,0x40001000,0,30)
joint(256,0x40000000,0,100);joint(320,0x100000,0,200);joint(384,0x100000,2,5)
ptr(64+8,128);ptr(128+8,256);ptr(128+12,192);ptr(192+8,256);ptr(192+12,256)
ptr(256+8,384);ptr(256+12,320);ptr(320+0x10,512);ptr(384+0x10,512)
ptr(512+12,576);ptr(576+8,640);ptr(576+16,800);u16(576+14,4)
for i,s in ipairs{{9,1,4},{10,0,4},{11,1,5},{13,1,4}}do
 local off=640+(i-1)*24;u32(off,s[1]);u32(off+4,1);u32(off+8,s[2]);u32(off+12,s[3])
end
u32(736,255);put(800,string.char(0x90,0,3))
local off=803
for _,pos in ipairs{{0,0,0},{1,0,0},{0,1,0}}do
 for _,v in ipairs{pos[1],pos[2],pos[3],1,0,0}do f32(off,v);off=off+4 end
 put(off,string.char(64,128,192,255));off=off+4;f32(off,.25);f32(off+4,.75);off=off+8
end
local function archive()return {blob=table.concat(bytes),base=0,fileSize=2048,data=0,dataSize=2048,ptr=function(_,p)return pointers[p]end}end
local function extract(extra)
 local o={nativeSceneInstances=true,textures=false,preserveVertexColors=true,minVertices=3,maxVertices=60}
 for k,v in pairs(extra or {})do o[k]=v end
 return H._test.extractRoot(archive(),64,o)
end
local model,why,stats=extract();check(model~=nil,why)
check(#model.groups==4 and model.vertexCount==12,'shared target deduplicated or target sibling duplicated')
check(stats.sceneInstances==2,'native instance count lost')
local expected={{0,15,-2},{2,35,0},{2,105,0},{0,200,0}}
for gi,xyz in ipairs(expected)do
 local v=model.groups[gi].vertices[1]
 for k=1,3 do near(v[k],xyz[k],'instance/normal placement '..gi..' axis '..k)end
 near(v[4],.25,'instance U changed');near(v[5],.75,'instance V changed')
 near(v[6],64/255,'instance source red changed');near(v[7],128/255,'instance source green changed');near(v[8],192/255,'instance source blue changed');near(v[9],1,'instance source alpha changed')
end
near(model.groups[1].vertices[1][10],0,'instance normal X');near(model.groups[1].vertices[1][12],-1,'instance normal Z')
near(model.groups[2].vertices[1][10],1,'other instance inherited first rotation')
local actor=assert(extract({nativeSceneInstances=false}))
check(#actor.groups==2 and actor.vertexCount==6,'actor opt-out geometry/group order changed')
local limited,err=extract({maxVertices=9});check(limited==nil and err=='mesh vertex budget','instance vertices bypassed source extraction budget')
u32(128+4,0x40001010)
local hidden=assert(extract());check(#hidden.groups==3 and hidden.vertexCount==9,'hidden instance submitted geometry or hid the shared template')
near(hidden.groups[1].vertices[1][2],35,'visible second instance lost after hidden first placement')
-- Scene assembly must propagate failures instead of silently skipping the
-- failed crowd modelset and publishing the rest of an incomplete venue.
u32(128+4,0x40001000)
ptr(1024,1040);ptr(1040,1056);ptr(1056,64)
H.findArchives=function()local a=archive();a.publicSymbol=function()return 1024 end;return {a}end
local partial,problem=H.extractSceneModel('fixture',{nativeSceneInstances=true,textures=false,minVertices=3,maxVertices=9})
check(partial==nil and problem:find('mesh vertex budget',1,true),'scene assembly hid instance budget failure')
ptr(128+8,448)
local missing,reason=H.extractSceneModel('fixture',{nativeSceneInstances=true,textures=false,minVertices=3,maxVertices=60})
check(missing==nil and reason:find('unresolved scene instance target',1,true),'scene assembly hid unresolved instance')
print('PresentationFidelitySweepSceneInstanceTests: '..checks..' assertions passed')
return true
