local VM=assert(loadfile('lib/MoveFXVM.lua'))()
local spec={style='projectile',textures={{bank=1}},generatorPrograms={{phase='attack',bank=1,scriptId=0,bankIndex=0,root=true,angleFlags=0,animIndex=0,maxLife=8,repeatCount=30,flags=0x400,gravity=0,friction=1,velocityX=0,velocityY=0,velocityZ=0,radius=0,angle=0,emissionRate=-1,particleSize=1,commandHex='14FE'}}}
local fx=VM.start(spec,{role='attack',entry={phase='attack',bank=1,selector=0},sequenceStartHandled=true,sourceDurationFrames=8})
fx.emissionOrigin={0,0,0};VM.update(fx,1/60)
local first=assert(fx.particles[1]);fx.emissionOrigin={10,4,2};VM.update(fx,1/60)
assert(first.position[1]==0 and first.position[2]==0,'emitted particles dragged with mouth')
local last=fx.particles[#fx.particles]
assert(last~=first and last.position[1]==10 and last.position[2]==4 and last.position[3]==2,'emitter stuck at original attachment')
spec.generatorPrograms[1].flags=0x8400
local attached=VM.start(spec,{role='attack',entry={phase='attack',bank=1,selector=0},sequenceStartHandled=true,sourceDurationFrames=8})
attached.emissionOrigin={10,4,2};VM.update(attached,1/60)
assert(attached.particles[1].position[1]==0,'joint-follow particle received attachment twice')
local inst={serial=1,presentationSerial=1,role='attack',side='player',target='enemy',frame=10,sourceEndFrame=100,spec=spec,entries={}}
local waza={active={inst}}
local H=assert(loadfile('lib/WazaHandlers.lua'))({WazaSequenceRuntime=waza,CurrentSpriteModels={wazaBasis=function(_,ctx,side,target)
 local src=side=='player' and {0,5,0} or {0,5,100}
 local dst=side=='player' and {0,5,100} or {0,5,0}
 return {origin=src,target=dst,forward={0,0,side=='player' and 1 or -1},right={1,0,0},fightDistance=100,sourceVisualHeight=10,targetVisualHeight=10}
end}})
local a=H.cameraPose({});inst.frame=90;local b=H.cameraPose({})
assert(a.cut and a.focus[3]==b.focus[3] and a.focus[3]<20,'launch camera chases beam away from attacker')
inst.serial=2;inst.role='damage';inst.frame=0
local c=H.cameraPose({});assert(c.focus[3]==100 and c.cut,'damage cut interpolated through arena')
print('PASS: moving emitter, independent particles, joint-follow ownership, held launch and damage cut')
