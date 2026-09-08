local root=(arg and arg[0] or ''):gsub('tests[/\\]MoveFXRetailParticleRuntimeTests.lua$','')
if root=='' then root='./' end
local VM=assert(loadfile(root..'lib/MoveFXVM.lua'))()
local function eq(a,b,msg) assert(a==b,(msg or 'mismatch')..': '..tostring(a)..' ~= '..tostring(b)) end
local function truth(v,msg) assert(v,msg or 'expected true') end

-- AC is time + base float + range float; 1.9.x consumed only one float and
-- desynchronised every following opcode. F1 is a u16 table id; the following byte is an opcode.
truth(VM.programSupported('AC003F8000003F000000FE'),'AC retail framing')
truth(VM.programSupported('F1000207FE'),'F1 retail framing')
truth(not VM.programSupported('F100'),'truncated F1 must fail')

local spec={textures={{bank=1}},lookupTables={[1]={[0]=1}},generatorPrograms={
  {phase='attack',bank=1,sourceBank=1,scriptId=0,bankIndex=0,root=true,angleFlags=0,animIndex=0,
   maxLife=3,repeatCount=2,flags=0x400,gravity=0,friction=1,velocityX=0,velocityY=0,velocityZ=.1,
   radius=0,angle=0,emissionRate=-1,particleSize=2,shapeX=0,shapeY=0,shapeZ=0,
   commandHex='01FE'},
  {phase='attack',bank=1,sourceBank=1,scriptId=1,bankIndex=1,root=false,angleFlags=0,animIndex=0,
   maxLife=1,repeatCount=4,flags=0x400,gravity=0,friction=1,velocityX=0,velocityY=.1,velocityZ=0,
   radius=0,angle=0,emissionRate=-1,particleSize=1,shapeX=0,shapeY=0,shapeZ=0,
   commandHex='01FE'},
}}
local fx=VM.start(spec,{role='attack',entry={phase='attack',bank=1,selector=0},sequenceStartHandled=true,sourceDurationFrames=10})
eq(#fx.generators,1,'root selector must start one retail generator')
VM.update(fx,1/60)
eq(#fx.particles,1,'negative emission rate -1 emits exactly one particle per frame')
eq(fx.particles[1].size,2,'particleSize comes from +0x2C')
eq(fx.particles[1].repeatCount,2,'source +0x06 becomes repeatCount+1 then decrements per frame')

-- Table-addressed F2 must resolve through FieldParticleFile +0x10 bank data,
-- not through the old fake per-script REF ownership model.
local spec2={textures={{bank=1}},lookupTables={[1]={[0]=1}},generatorPrograms={
  {phase='attack',bank=1,scriptId=0,bankIndex=0,root=true,angleFlags=0,animIndex=0,maxLife=1,repeatCount=1,flags=0x400,
   gravity=0,friction=1,velocityX=0,velocityY=0,velocityZ=0,radius=0,angle=0,emissionRate=-1,particleSize=1,shapeX=0,shapeY=0,shapeZ=0,
   commandHex='F20000FE'},
  {phase='attack',bank=1,scriptId=1,bankIndex=1,angleFlags=0,animIndex=0,maxLife=0,repeatCount=5,flags=0x400,
   gravity=0,friction=1,velocityX=.1,velocityY=0,velocityZ=0,radius=0,angle=0,emissionRate=0,particleSize=1,shapeX=0,shapeY=0,shapeZ=0,
   commandHex='01FE'},
}}
local fx2=VM.start(spec2,{role='attack',entry={phase='attack',bank=1,selector=0},sequenceStartHandled=true,sourceDurationFrames=5})
VM.update(fx2,1/60)
local found=false;for _,p in ipairs(fx2.particles) do if p.scriptId==1 then found=true end end
truth(found,'F2 table lookup must spawn script id from GPT1 bank-data table')
truth(#(fx2.opcodeFaults or {})==0,'verified fixture must have no opcode faults')
-- Source Seismic Toss/Vital Throw place a delay or CF color command immediately
-- after F1's table id. Consuming that opcode as an argument corrupts the stream.
spec2.generatorPrograms[1].commandHex='F10000CF001122334405FE'
local fx3=VM.start(spec2,{role='attack',entry={phase='attack',bank=1,selector=0},sequenceStartHandled=true,sourceDurationFrames=5})
VM.update(fx3,1/60)
local rootParticle
for _,p in ipairs(fx3.particles)do if p.scriptId==0 then rootParticle=p end end
truth(rootParticle,'F1 fixture lost root particle')
for i,v in ipairs({0x11,0x22,0x33,0x44})do eq(rootParticle.prim[i],v,'F1 swallowed following color opcode') end
truth(#(fx3.opcodeFaults or {})==0,'F1 boundary produced an opcode fault')
print('MoveFXRetailParticleRuntimeTests: OK')
