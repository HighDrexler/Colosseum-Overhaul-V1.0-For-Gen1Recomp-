-- ROM-free regression fixtures for the disappearing middle-of-attack layer.
local root=(arg and arg[0] or ''):gsub('tests[/\\]MoveFXTransitRegressionTests.lua$','')
if root=='' then root='./' end
local count=0
local function eq(a,b,msg) count=count+1;assert(a==b,(msg or '')..': '..tostring(a)..' ~= '..tostring(b)) end
local function near(a,b,msg) count=count+1;assert(math.abs(a-b)<1e-7,(msg or '')..': '..a..' ~= '..b) end
local function yes(v,msg) count=count+1;assert(v,msg) end
local VM=assert(loadfile(root..'lib/MoveFXVM.lua'))()
local function program(extra)
 local g={phase='attack',bank=1,sourceBank=1,scriptId=0,bankIndex=0,root=true,angleFlags=0,animIndex=0,
  maxLife=1,repeatCount=80,flags=0x400,gravity=9,friction=0,velocityX=0,velocityY=0,velocityZ=2,
  radius=0,angle=0,emissionRate=-1,particleSize=2,shapeX=0,shapeY=0,shapeZ=0,commandHex='1FFE'}
 for k,v in pairs(extra or {}) do g[k]=v end
 return g
end
local function start(g,extra)
 local spec={textures={{bank=1}},generatorPrograms={g},duration=2}
 for _,child in ipairs(extra or {}) do spec.generatorPrograms[#spec.generatorPrograms+1]=child end
 return VM.start(spec,{role='attack',entry={phase='attack',bank=1,selector=0},sequenceStartHandled=true,sourceDurationFrames=8}),spec
end
-- Unused friction=0/gravity=9 must not erase native velocity. Actual GPT1
-- secondary Flamethrower programs carry unused zero friction in this manner.
local fx=start(program());VM.update(fx,1/60)
eq(#fx.particles,1,'first emission');near(fx.particles[1].position[3],2,'forward movement');near(fx.particles[1].position[2],0,'gravity disabled')
VM.update(fx,4/60);near(fx.particles[1].position[3],10,'travel survives unused friction')
local stopped=start(program{flags=0x402});VM.update(stopped,1/60);near(stopped.particles[1].position[3],0,'explicit friction flag honored')
local damped=start(program{flags=0x402,friction=.5});VM.update(damped,2/60);near(damped.particles[1].position[3],1.5,'source damping')
local gravity=start(program{flags=0x401,gravity=.5});VM.update(gravity,2/60);near(gravity.particles[1].position[2],-1.5,'source gravity')
local stopOpcode=start(program{commandHex='A3000000001FFE'});VM.update(stopOpcode,1/60);near(stopOpcode.particles[1].velocity[3],0,'A3 zero enables friction')
local restoreOpcode=start(program{flags=0x402,commandHex='A33F8000001FFE'});VM.update(restoreOpcode,1/60);near(restoreOpcode.particles[1].position[3],2,'A3 one disables damping')
local fallOpcode=start(program{commandHex='A23F0000001FFE'});VM.update(fallOpcode,1/60);near(fallOpcode.particles[1].position[2],-.5,'A2 enables gravity')
local noFallOpcode=start(program{flags=0x401,commandHex='A2000000001FFE'});VM.update(noFallOpcode,1/60);near(noFallOpcode.particles[1].position[2],0,'A2 zero disables gravity')
-- dt partition invariance; natural particle tail outlives the emitter/chapter.
local a=start(program{maxLife=4,commandHex='1F1F1FFE'});local b=start(program{maxLife=4,commandHex='1F1F1FFE'})
for i=1,30 do VM.update(a,1/60) end
for i=1,10 do VM.update(b,3/60) end
eq(a.frame,b.frame,'partition clock');eq(#a.particles,#b.particles,'partition emissions')
for i,p in ipairs(a.particles) do for k=1,3 do near(p.position[k],b.particles[i].position[k],'partition position') end end
yes(not a.done and #a.particles>0,'chapter boundary must not kill living particles')
for i=1,100 do VM.update(a,1/60) end
yes(a.done,'natural drain');eq(a.finishReason,'source-objects-drained','no watchdog');eq(#a.opcodeFaults,0,'no faults')
local frame=a.frame;VM.update(a,1);eq(a.frame,frame,'completed effect is inert')
-- Float operands containing AA/F1/F2 are not child opcodes.
eq(VM.programSpawnsChildren('A33FAA00001FFE'),false,'operand byte not a child opcode')
eq(VM.programSpawnsChildren('F100001FFE'),true,'actual F1 detected')
eq(VM._test.selectRoot({generatorPrograms={program{bank=2,sourceBank=2}}},{phase='attack',bank=1,selector=0},'attack'),nil,'no unrelated bank fallback')
-- Each particle freezes its own source-model birth matrix, independent of
-- subsequent model transforms and script-local position writes.
local frozen=start(program{maxLife=3,commandHex='84000000001FFE'})
frozen.emissionTransform={1,0,0,0,0,1,0,0,0,0,1,10}
VM.update(frozen,1/60);local first=frozen.particles[1];eq(first.attachmentMatrix[12],10,'birth part translation')
frozen.emissionTransform[12]=20;VM.update(frozen,1/60)
eq(first.attachmentMatrix[12],10,'existing foam never slides to new part');eq(frozen.particles[2].attachmentMatrix[12],20,'next birth uses moved part')
near(first.position[3],4,'local position command did not eat model transform')
local child=program{scriptId=1,bankIndex=1,root=false,maxLife=1,velocityZ=0,commandHex='1FFE'}
local inherited=start(program{commandHex='A400011FFE'},{child})
inherited.emissionTransform={1,0,0,0,0,1,0,0,0,0,1,36};VM.update(inherited,1/60)
local cp;for _,p in ipairs(inherited.particles) do if p.scriptId==1 then cp=p end end
yes(cp,'child spawned');eq(cp.attachmentMatrix[12],36,'child retains source-model frame')
local gchild=start(program{commandHex='A500011FFE'},{child})
gchild.emissionTransform={1,0,0,0,0,1,0,0,0,0,1,42};VM.update(gchild,2/60)
local gp;for _,p in ipairs(gchild.particles) do if p.scriptId==1 then gp=p end end
yes(gp,'child generator spawned');eq(gp.attachmentMatrix[12],42,'child generator retains part frame')
-- Regression for Lua's and/or fallback returning the warm STATIC shader when
-- the first morph shader is cold. A strict stub rejects unknown uniforms.
local oldLove=love;local made={}
love={graphics={newShader=function(vertex,pixel)
 local sh={morph=vertex:find('uniform float w0',1,true)~=nil,vertex=vertex}
 function sh:send(name,...) if name=='w0' then assert(self.morph,'static shader received w0') end end
 made[#made+1]=sh;return sh
end}}
local H=assert(loadfile(root..'lib/WazaHandlers.lua'))({})
local static=H._test.ensureShader(false);local morph=H._test.ensureShader(true)
eq(#made,2,'compile distinct static and morph shaders');yes(static~=morph,'morph never falls back to static');yes(morph.morph,'morph uniforms present');morph:send('w0',1)
eq(H._test.ensureShader(true),morph,'warm morph reuse');eq(H._test.ensureShader(false),static,'warm static reuse')
love=oldLove
local identity={origin={0,0,0},right={1,0,0},up={0,1,0},forward={0,0,1},modelTargetSpan=20}
local asset={bounds={min={0,0,0},max={0,0,0}},normalizationBounds={min={-50,0,-50},max={50,30,50}}}
local matrix=H._test.modelMatrix(identity,{bounds={min={0,0,0},max={1,1,1}}},asset)
near(matrix[1],.2,'collapsed first pose uses clip union')
local m2=H._test.modelMatrix(identity,{bounds={min={-100,0,0},max={100,1,1}}},asset)
for i=1,16 do near(matrix[i],m2[i],'morph page never changes world scale') end
local function basis(ctx,reverse,height,targets)
 local V={};V.CurrentSpriteModels=assert(loadfile(root..'lib/CurrentSpriteModels.lua'))(V)
 local C=V.CurrentSpriteModels
 ctx=ctx or {groundY=3,arena={player={0,reverse and 50 or -50},enemy={0,reverse and -50 or 50}},cbeWazaTargets=targets}
 C.stadiumActors={}
 for _,side in ipairs({'player','enemy'}) do
  local p=ctx.arena[side];local actor={height=height,worldScale=1}
  function actor:attachment(name) return {position={p[1],height*.5,p[2]}} end
  C.stadiumActors[side]={actor=actor}
 end
 return C:wazaBasis(ctx,'player','enemy',1,{moveId=57,role='attack',sourceStrict=true}),C,ctx
end
local wave,C,ctx=basis(nil,false,2)
local big=basis(nil,false,80)
yes(wave.fieldWave,'Surf is field-space');near(wave.origin[3],0,'wave common lane midpoint');near(wave.origin[2],3,'wave uses floor')
for _,axis in ipairs({'x','y','z'}) do near(wave.sourceUnits[axis],1,'native field unit');near(big.sourceUnits[axis],wave.sourceUnits[axis],'independent of Pokemon size') end
local reverse=basis(nil,true,24);near(wave.forward[3],-reverse.forward[3],'reversed battle direction')
local spread=basis(nil,false,24,{{-20,60},{20,80}});near(spread.origin[3],10,'spread target centroid');near(spread.sourceUnits.z,1.2,'spread field distance')
local hit=C:wazaBasis(ctx,'enemy','player',1,{moveId=57,role='damage',sourceStrict=true});eq(hit.fieldWave,false,'receiving chapter not another tidal wave')
local partData='return {revision=1,endFrame=1,tracks={[2]={{1,0,0,0,0,1,0,0,0,0,1,0},{1,0,0,0,0,1,0,0,0,0,1,10}}}}'
local HV={CurrentSpriteModels=C,GeneratedAssets={read=function(path)if path=='fixture_parts.lua' then return partData end end}}
local partsH=assert(loadfile(root..'lib/WazaHandlers.lua'))(HV)
local entry={kind='particle',phase='attack',flags=1,linkedEntryKey=7,partIndex=2}
local model={kind='model',phase='attack',identifier=7,attachment=1,modelAsset={parts={path='fixture_parts.lua'}}}
local inst={role='attack',moveId=57,side='player',target='enemy',frame=.5,entries={{started=true,startFrame=0,entry=model}}}
local linked=assert(partsH.linkedParticleFrame(ctx,inst,entry));near(linked.part[12],5,'interpolated linked source part');eq(linked.modelIdentifier,7,'linked model exact id')
linked.part[12]=999;local fresh=assert(partsH.linkedParticleFrame(ctx,inst,entry));near(fresh.part[12],5,'detached sampled transform')
inst.entries[1].started=false;eq(partsH.linkedParticleFrame(ctx,inst,entry),nil,'unstarted link rejected');inst.entries[1].started=true
entry.phase='damage';eq(partsH.linkedParticleFrame(ctx,inst,entry),nil,'cross-chapter link rejected');entry.phase='attack'
entry.partIndex=3;eq(partsH.linkedParticleFrame(ctx,inst,entry),nil,'missing effect part never falls back to Pokemon');entry.partIndex=2
local other={role='attack',moveId=57,side='player',target='enemy',frame=.5,entries={}}
eq(partsH.linkedParticleFrame(ctx,other,entry),nil,'no other-instance model borrowed')
local Policy=assert(loadfile(root..'lib/WazaPhasePolicy.lua'))({})
local full={wazaPhases={{name='attack'},{name='special'},{name='damage'}},sounds={{phase='attack',soundId=1},{phase='special',soundId=2},{phase='damage',soundId=3},{soundId=4}}}
local selected=Policy.select(full);eq(#selected.sounds,3,'unused charge sounds excluded from attack readiness');eq(#full.sounds,4,'source unchanged')
local charge=Policy.select(full,{stage='charge'});eq(charge.sounds[1].soundId,2,'charge retains charge sound');eq(charge.sounds[2].soundId,3,'damage sound retained')
local tint={11,22,33,44}
eq(H._test.keyedColor({{from=0,to=.35,duration=10}},.5,tint),tint,'scalar energy is not RGBA')
local tint2=H._test.keyedColor({{from={0,20,40,60},to={20,40,60,80},duration=10}},.5)
for i,x in ipairs({10,30,50,70}) do near(tint2[i],x,'RGBA interpolates normally') end
-- A tiny independently authored HSD fixture: one joint at data offset zero,
-- explicitly relocated from one scene model-set. No ROM/model bytes are used.
local function u32(n) return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,math.floor(n/256)%256,n%256) end
local function skeleton(relocated)
 local bytes={};for i=1,256 do bytes[i]=0 end
 local function word(at,n)local b=u32(n);for i=1,4 do bytes[at+i]=b:byte(i) end end
 for _,at in ipairs({0x20,0x24,0x28}) do word(at,0x3f800000) end -- unit scale
 word(0x60,0x70);word(0x70,0x80);word(0x80,0) -- root is valid data offset 0
 local rel=u32(0x60)..u32(0x70)..(relocated and u32(0x80) or '')
 local body=string.char(unpack(bytes));local tail=rel..u32(0x60)..u32(0)..'scene_data\0'
 return u32(32+#body+#tail)..u32(#body)..u32(relocated and 3 or 2)..u32(1)..u32(0)..string.rep('\0',12)..body..tail
end
local HD=assert(loadfile(root..'extract/HSD.lua'))({})
local sk=skeleton(true)
local opts={semanticRootsOnly=true,allowTransformOnly=true,preserveJointMatrices=true}
local carrier,why=HD.extractModel(sk,opts);yes(carrier,why)
eq(carrier.vertexCount,0,'transform-only is not invented geometry');yes(carrier.transformOnly,'explicit carrier classification')
eq(#carrier.jointMatrices,1,'source carrier has an exact joint frame');near(carrier.jointMatrices[1][1],1,'carrier scale retained')
eq(HD.extractModel(sk,{semanticRootsOnly=true}),nil,'ordinary Pokemon/arena extraction still rejects empty mesh')
eq(HD.extractModel(sk,{allowTransformOnly=true,preserveJointMatrices=true}),nil,'heuristic roots cannot become carriers')
eq(HD.extractModel(skeleton(false),opts),nil,'unrelocated zero is NULL, not a source joint')

print('MoveFXTransitRegressionTests: '..count..' assertions passed')
