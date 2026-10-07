local V = ...
local Trainer = V and V.Trainer
local PlayerTrainer = V and V.PlayerTrainer
local BattleDirector=V and V.BattleDirector
local CurrentSpriteModels=V and V.CurrentSpriteModels
local C = {}
local Pacing=V and V.CameraPacing

local DEFAULT = {orbit=1.33,elevation=0.46,radius=64,fov=40,focus={0,6.3,0}}
local MANUAL_RELEASE_DELAY = 1.35
local AUTO_RETURN_BLEND = 0.72
local AUTHORED_ZOOM_OUT = 1.045




local MOBILE_AUTO_PULLBACK = 1.16
local MOBILE_ACTION_PULLBACK = 1.10
local MOBILE_AUTO_FOV_BONUS = math.rad(1.8)
local MOBILE_ACTION_FOV_BONUS = math.rad(2.8)





local EVENT_HOLDS = {
attack = 1.02,
damage = 0.88,
reaction = 0.96,
capture = 1.35,
faint = 2.05,
switch = 1.42,
exit = 1.22,
passive = 1.05,
command = 1.05,
}
local EVENT_PRIORITY = { passive=0, command=1, attack=2, damage=3, reaction=3, capture=4, switch=4, faint=5, exit=6 }
local MIN_INTERRUPT_AGE = 0.58







local PASSIVE_RANDOM_INTERVAL = 200/60
local PASSIVE_RANDOM_GATE = 0.50





local PASSIVE_FLOOR_SETTLE_DURATION = 1.50
local PASSIVE_FLOOR_SETTLE_DISTANCE = 4.0




local function battleSpeed(ctx)
if Pacing then return Pacing.speed(ctx,nil,V and V.mod) end
local b=type(ctx)=="table" and (ctx.battle or (ctx.kind and ctx)) or nil
local game=(b and b.game) or (ctx and ctx.game) or (V and V.mod and V.mod.game)
local speed
if game and type(game.logicSpeed)=="function" then
local ok,value=pcall(game.logicSpeed,game)
if ok then speed=tonumber(value) end
end
if not speed then
local opts=game and game.save and game.save.options
speed=tonumber(opts and (opts.speedBattle or opts.speed)) or 1
end
if speed~=speed or speed<1 or math.abs(speed)==math.huge then speed=1 end
return speed
end

local function holdScale(speed)


return 1
end

local function phaseAllowedAtSpeed(phase,speed)



return true
end








local PASSIVE_FALLBACK_TABLE_EXACT=false
local PASSIVE_SHOTS = {








{owner="player-pokemon",eye={55,25,6}, focus={0,6.2,0},fov=36,hold=6.20,travel={-2.2,.55,-1.0},focusTravel={0,.10,0},arc=math.rad(14),lateral=10,dolly=.10},
{owner="enemy-pokemon", eye={-54,25,-6}, focus={0,6.2,0},fov=36,hold=6.00,travel={2.1,.55,1.0},focusTravel={0,.10,0},arc=math.rad(-14),lateral=10,dolly=.10},
{owner="player-trainer",eye={-32,22,42}, focus={0,6.4,0},fov=36,hold=5.80,travel={1.6,.45,-1.3},focusTravel={-.30,.08,-.40},arc=math.rad(11),lateral=9,dolly=.10},
{owner="enemy-trainer", eye={32,22,-42}, focus={0,6.4,0},fov=36,hold=5.80,travel={-1.6,.45,1.3},focusTravel={.30,.08,.40},arc=math.rad(-11),lateral=9,dolly=.10},
}










local COMMAND_FALLBACK_TABLE_EXACT=false
local RETAIL_FLOOR_CAMERA_ANIMATION_ID=0x7B1800
local RETAIL_FLOOR_CAMERA_ANIMATION_RATE=0.5








local RETAIL_FLOOR_CAMERA_SCALE={
[1]=1.1000000238418579,
[2]=1.2000000476837158,
[3]=1.3999999761581421,
}
local function retailFloorCameraScale(selector)
return RETAIL_FLOOR_CAMERA_SCALE[tonumber(selector)] or 1.0
end
local function retailFloorCameraMaxSelector(selectors)
local maxSelector=0
for _,value in ipairs(type(selectors)=="table" and selectors or {}) do
value=tonumber(value)
if value and value>maxSelector then maxSelector=value end
end
return maxSelector
end
local function retailFloorCameraOffsetPose(sample,selectors)
if type(sample)~="table" or type(sample.eye)~="table" or type(sample.focus)~="table" then return nil end
local selector=retailFloorCameraMaxSelector(selectors)
local scale=retailFloorCameraScale(selector)




return {
eye={(tonumber(sample.eye[1]) or 0)*scale,(tonumber(sample.eye[2]) or 0)*scale,(tonumber(sample.eye[3]) or 0)*scale},
focus={(tonumber(sample.focus[1]) or 0)*scale,(tonumber(sample.focus[2]) or 0)*scale,(tonumber(sample.focus[3]) or 0)*scale},
fov=sample.fov,
},{selector=selector,scale=scale,position={0,0,0},rotation={0,0,0},worldUp={0,1,0},exact=true}
end







local function liveRetailFloorScale()
local kinds={}
local function add(a)
local m=type(a)=="table" and a.sourceMetadata
local v=type(m)=="table" and tonumber(m.sequenceKind~=nil and m.sequenceKind or m.scaleSelector)
if v then kinds[#kinds+1]=v end
end
local models=CurrentSpriteModels or (V and V.CurrentSpriteModels)
if models and type(models.stadiumActors)=="table" then
for _,rec in pairs(models.stadiumActors) do add(type(rec)=="table" and rec.actor) end
end
local G=V and V.Gen3Presentation
if G and type(G.records)=="table" then
for _,r in pairs(G.records) do add(type(r)=="table" and r.actor) end
end
return retailFloorCameraScale(retailFloorCameraMaxSelector(kinds))
end
local function sizeClassDolly(pose,scale,groundY)
if not (pose and pose.eye and pose.focus) or math.abs((scale or 1)-1)<1e-4 then return pose end
local f=pose.focus;local g=tonumber(groundY) or 0
local focus={f[1],g+(f[2]-g)*scale,f[3]}
return {eye={focus[1]+(pose.eye[1]-f[1])*scale,focus[2]+(pose.eye[2]-f[2])*scale,focus[3]+(pose.eye[3]-f[3])*scale},
focus=focus,fov=pose.fov}
end
local COMMAND_SHOTS = {
{eye={67,31,8},focus={0,6.2,0},fov=48,hold=6.2,blend=1.25,travel={-1.8,.4,-.5}},
{eye={66,32,-8},focus={0,6.2,0},fov=48,hold=6.0,blend=1.25,travel={-1.2,-.1,.7}},
{eye={64,30,2},focus={0,6.2,0},fov=47,hold=6.1,blend=1.2,travel={1.0,.35,.6}},
}


local state = {
time=0, idleClock=0, phaseAge=0, phase="intro", lastPose=nil, startPose=nil,
eventSide=nil,eventIndex=0,eventResult=nil,resultPending=nil,resultAt=0,shotOffset=0,special=nil,specialUntil=0,
actionAxisAttacker=nil,actionAxisSign=nil,
passiveShotIndex=1,passiveShotAge=0,passiveTimer=PASSIVE_RANDOM_INTERVAL,passiveRng=1,
passiveMotionMode=2,passiveLastMotionMode=nil,passiveSourcePlan=nil,passiveSourceTargetResolved=false,
manual=false, manualLocked=false, manualIdle=0, returning=false, keys={},
shotLockUntil=0,pendingEvent=nil,lastCutTime=-999,lastEventName=nil,logicSpeed=1,
sourcePose=nil,sourcePoseAt=0,sourceIdentity=nil,sourceHandoff=nil,sourceHandoffAt=0,
orbit=DEFAULT.orbit,elevation=DEFAULT.elevation,radius=DEFAULT.radius,fov=DEFAULT.fov,
focus={DEFAULT.focus[1],DEFAULT.focus[2],DEFAULT.focus[3]},
mouseX=nil,mouseY=nil,
}

local function clamp(v,a,b) if v<a then return a elseif v>b then return b else return v end end
local function atan2(y,x)
if math.atan2 then return math.atan2(y,x) end
if x>0 then return math.atan(y/x) end
if x<0 then return math.atan(y/x)+(y>=0 and math.pi or -math.pi) end
return y>0 and math.pi/2 or (y<0 and -math.pi/2 or 0)
end
local function smooth(t) t=clamp(t,0,1); return t*t*(3-2*t) end
local function copy3(v) return {v[1],v[2],v[3]} end
local function copyPose(p)
if not p then return nil end
return {eye=copy3(p.eye),focus=copy3(p.focus),fov=p.fov}
end
local function validSourcePose(p)
if type(p)~="table" or type(p.eye)~="table" or type(p.focus)~="table" then return false end
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
if not finite(p.fov) or p.fov<=0 or p.fov>=math.pi then return false end
local distance=0
for i=1,3 do
if not finite(p.eye[i]) or not finite(p.focus[i]) then return false end
distance=distance+(p.eye[i]-p.focus[i])^2
end
return distance>1e-10
end
local function orbitPolar(p)
local x,y,z=p.eye[1]-p.focus[1],p.eye[2]-p.focus[2],p.eye[3]-p.focus[3]
local h=math.sqrt(x*x+z*z)
return atan2(x,z),atan2(y,math.max(.000001,h)),math.sqrt(h*h+y*y)
end




local function lockedYawDelta(ay,by,sign)
local d=(by-ay+math.pi)%(2*math.pi)-math.pi
if sign and sign~=0 and math.abs(d)>math.pi*.75 and (d>0)~=(sign>0) then d=d+(sign>0 and 2 or -2)*math.pi end
return d
end
local function orbitMix(a,b,t,sign)
if not a then return copyPose(b) end
t=clamp(t,0,1)
local ay,ap,ar=orbitPolar(a);local by,bp,br=orbitPolar(b)
local yaw=ay+lockedYawDelta(ay,by,sign)*t
local pitch=ap+(bp-ap)*t;local radius=ar+(br-ar)*t
local focus={a.focus[1]+(b.focus[1]-a.focus[1])*t,
a.focus[2]+(b.focus[2]-a.focus[2])*t,a.focus[3]+(b.focus[3]-a.focus[3])*t}
local h=math.cos(pitch)*radius
return {eye={focus[1]+math.sin(yaw)*h,focus[2]+math.sin(pitch)*radius,focus[3]+math.cos(yaw)*h},
focus=focus,fov=a.fov+(b.fov-a.fov)*t}
end


local mixSigns=setmetatable({},{__mode="k"})





local editCuts=setmetatable({},{__mode="k"})
local function editIsCut(a,b)
local ay,ap,ar=orbitPolar(a);local by,bp,br=orbitPolar(b)
local yaw=math.abs((by-ay+math.pi)%(2*math.pi)-math.pi)
local fd=0;for i=1,3 do fd=fd+(a.focus[i]-b.focus[i])^2 end
return yaw>math.rad(70) or math.abs(bp-ap)>math.rad(28) or math.sqrt(fd)>math.max(10,ar*.55)
end
local function mix(a,b,t)
if not a then return copyPose(b) end
local sign=mixSigns[a]
if not sign then
local ay=orbitPolar(a);local by=orbitPolar(b)
sign=((by-ay+math.pi)%(2*math.pi)-math.pi)>=0 and 1 or -1
mixSigns[a]=sign
end
return orbitMix(a,b,smooth(t),sign)
end
local function edit(a,b,t)
if not a then return copyPose(b) end
local cut=editCuts[a]
if cut==nil then cut=editIsCut(a,b);editCuts[a]=cut end
if cut then return copyPose(b) end
return mix(a,b,t)
end



local function presentPose(pose,exact,manual)
if not (love and love.timer and type(love.timer.getTime)=="function") then return pose end
local ok,now=pcall(love.timer.getTime)
if not ok or type(now)~="number" or now~=now or math.abs(now)==math.huge then return pose end
local dt=state.displayClock and clamp(now-state.displayClock,0,.10) or 0
state.displayClock=now





local previous=state.presentInput
state.presentInput=copyPose(pose)
local cut=false
if previous then
local ay,ap,ar=orbitPolar(previous);local by,bp,br=orbitPolar(pose)
local eyeStep=0;for i=1,3 do eyeStep=eyeStep+(previous.eye[i]-pose.eye[i])^2 end
cut=math.sqrt(eyeStep)>math.max(6,ar*.25) or math.abs((by-ay+math.pi)%(2*math.pi)-math.pi)>math.rad(30)
or math.abs(bp-ap)>math.rad(20) or math.abs(pose.fov-previous.fov)>math.rad(10)
end
if exact or manual or cut or state.pacingOwnsDisplay or not state.displayPose then state.displayPose=copyPose(pose);state.displaySign=nil
else


local ay=orbitPolar(state.displayPose);local by=orbitPolar(pose)
local d=(by-ay+math.pi)%(2*math.pi)-math.pi
if math.abs(d)<math.pi*.5 then state.displaySign=nil
elseif not state.displaySign then state.displaySign=d>=0 and 1 or -1 end
state.displayPose=orbitMix(state.displayPose,pose,1-math.exp(-dt*9),state.displaySign)
end
return copyPose(state.displayPose)
end
local function approach(a,b,maxDelta)
local d=b-a
if d>maxDelta then return a+maxDelta end
if d< -maxDelta then return a-maxDelta end
return b
end
local function length3(x,y,z) return math.sqrt(x*x+y*y+z*z) end
local function approach3(a,b,maxDistance)
if not a then return copy3(b) end
local dx,dy,dz=b[1]-a[1],b[2]-a[2],b[3]-a[3]
local d=length3(dx,dy,dz)
if d<=maxDistance or d<1e-8 then return copy3(b) end
local q=maxDistance/d
return {a[1]+dx*q,a[2]+dy*q,a[3]+dz*q}
end
local function stableSourcePose(raw,retailExact,speed)
if not raw then state.sourcePose=nil;state.sourceIdentity=nil;state.sourcePoseAt=state.time;return nil end
local now=state.time
local identity=raw.sourceShotId or raw.sourceSerial




if retailExact then
state.sourceIdentity=identity;state.sourcePose=copyPose(raw);state.sourcePoseAt=now
return copyPose(raw)
end
if raw.cut and state.sourceIdentity~=identity then
state.sourceIdentity=identity;state.sourcePose=copyPose(raw);state.sourcePoseAt=now
return copyPose(raw)
end
state.sourceIdentity=identity
local dt=math.max(0,math.min(.08,now-(tonumber(state.sourcePoseAt) or now)))
state.sourcePoseAt=now
if not state.sourcePose then state.sourcePose=copyPose(raw);return copyPose(raw) end


local eyeSpeed=30
local focusSpeed=22
local fovSpeed=math.rad(24)
state.sourcePose.eye=approach3(state.sourcePose.eye,raw.eye,eyeSpeed*dt)
state.sourcePose.focus=approach3(state.sourcePose.focus,raw.focus,focusSpeed*dt)
state.sourcePose.fov=approach(state.sourcePose.fov,raw.fov,fovSpeed*dt)
return copyPose(state.sourcePose)
end
local function widenAuthored(pose)
if not pose then return pose end
local out=copyPose(pose)

out.fov=2*math.atan(math.tan(out.fov*0.5)*AUTHORED_ZOOM_OUT)
return out
end
local mobilePlatformCached=nil
local function mobilePlatform()
if mobilePlatformCached~=nil then return mobilePlatformCached end
if not (love and love.system and type(love.system.getOS)=="function") then return false end
local ok,osName=pcall(love.system.getOS)
if not ok then return false end
osName=tostring(osName or ""):lower()
mobilePlatformCached=(osName=="android" or osName=="ios")
return mobilePlatformCached
end







local function hudSafePose(pose,phase)
if not pose or not mobilePlatform() or phase=="free" then return pose end
local out=copyPose(pose)



local fx,fy,fz=out.focus[1],out.focus[2],out.focus[3]
out.eye={fx+(out.eye[1]-fx)*MOBILE_AUTO_PULLBACK,
fy+(out.eye[2]-fy)*1.08,
fz+(out.eye[3]-fz)*MOBILE_AUTO_PULLBACK}
out.fov=math.min(math.rad(53),out.fov+MOBILE_AUTO_FOV_BONUS)

local action=phase=="attack" or phase=="damage" or phase=="reaction" or phase=="faint"
if action then



out.focus[2]=out.focus[2]-1.70
fx,fy,fz=out.focus[1],out.focus[2],out.focus[3]
out.eye={fx+(out.eye[1]-fx)*MOBILE_ACTION_PULLBACK,
fy+(out.eye[2]-fy)*1.035,
fz+(out.eye[3]-fz)*MOBILE_ACTION_PULLBACK}
out.fov=math.min(math.rad(53),out.fov+MOBILE_ACTION_FOV_BONUS)
end
return out
end
local function arenaFrame(pose,arena)
if not pose then return pose end
local out=copyPose(pose)
local cam=arena and arena.camera
local side=cam and tonumber(cam.side) or 58
local baseK=clamp(side/58,0.93,1.10)




local radiusScale=clamp(cam and tonumber(cam.shotRadiusScale) or 1,0.55,1.20)
local heightScale=clamp(cam and tonumber(cam.shotHeightScale) or 1,0.55,1.20)
local k=baseK*radiusScale



local f=out.focus



local vertical=(1.08+0.16*baseK)*heightScale
out.eye={f[1]+(out.eye[1]-f[1])*k, f[2]+(out.eye[2]-f[2])*vertical, f[3]+(out.eye[3]-f[3])*k}



if arena and arena.id=="realgam_colosseum" then
out.eye[2]=out.eye[2]-.65
out.focus[2]=out.focus[2]+1.35
end
return out
end


local function finite(v)
return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
local function cameraAspect()
if love and love.graphics and type(love.graphics.getDimensions)=="function" then
local ok,w,h=pcall(love.graphics.getDimensions)
if ok and tonumber(w) and tonumber(h) and h>0 then return clamp(w/h,.45,2.5) end
end
return 16/9
end
local function safeCameraSpec(arena)
local c=arena and arena.camera
local s=c and c.safe or nil
return s or {minRadius=27,maxRadius=84,minY=6.5,maxY=42,maxPitch=32,minPitch=-10,minFov=31,maxFov=53}
end
local function clampCameraVolume(pose,arena,phase)
if not (pose and pose.eye and pose.focus) then return pose end
local out=copyPose(pose);local spec=safeCameraSpec(arena)
local free=phase=="free"
for i=1,3 do
if not finite(out.eye[i]) then out.eye[i]=(i==2 and 20 or (i==1 and 54 or 13)) end
if not finite(out.focus[i]) then out.focus[i]=(i==2 and 6 or 0) end
end
if not finite(out.fov) then out.fov=math.rad(40) end
out.fov=clamp(out.fov,math.rad(spec.minFov or 31),math.rad(spec.maxFov or 52))



if free then



out.focus[2]=clamp(out.focus[2],.75,math.max(1,math.min(24,(tonumber(spec.maxY) or 32)-1)))
else
out.focus[2]=clamp(out.focus[2],tonumber(spec.minFocusY) or 3.8,tonumber(spec.maxFocusY) or 9.2)
end
local dx,dz=out.eye[1]-out.focus[1],out.eye[3]-out.focus[3]
local horizontal=math.max(.001,math.sqrt(dx*dx+dz*dz))
local dy=out.eye[2]-out.focus[2]
local pitch=math.deg(atan2(dy,horizontal))
local maxPitch=free and 65 or (tonumber(spec.maxPitch) or 24)
local minPitch=free and -18 or (tonumber(spec.minPitch) or -10)



if phase=="attack" or phase=="damage" or phase=="reaction" then maxPitch=math.min(maxPitch,28) end
pitch=clamp(pitch,minPitch,maxPitch)
local radius=math.sqrt(horizontal*horizontal+dy*dy)
local minRadius=tonumber(spec.minRadius) or 27
if free then minRadius=math.max(12,minRadius*.65) end
radius=clamp(radius,minRadius,tonumber(spec.maxRadius) or 78)
local pr=math.rad(pitch);local hr=math.max(.001,math.cos(pr)*radius)
local oldh=math.sqrt(dx*dx+dz*dz)
local nx,nz
if oldh<.001 then nx,nz=1,0 else nx,nz=dx/oldh,dz/oldh end
out.eye[1]=out.focus[1]+nx*hr
out.eye[3]=out.focus[3]+nz*hr
out.eye[2]=clamp(out.focus[2]+math.sin(pr)*radius,tonumber(spec.minY) or 6.5,tonumber(spec.maxY) or 32)
return out
end
local arenaPoint,other,actionAxisSide,trainerVisible
local function projectPose(pose,p)
local ex,ey,ez=pose.eye[1],pose.eye[2],pose.eye[3]
local fx,fy,fz=pose.focus[1]-ex,pose.focus[2]-ey,pose.focus[3]-ez
local fl=math.sqrt(fx*fx+fy*fy+fz*fz);if fl<.001 then return nil end
fx,fy,fz=fx/fl,fy/fl,fz/fl

local rx,ry,rz=-fz,0,fx
local rl=math.sqrt(rx*rx+rz*rz);if rl<.001 then return nil end
rx,rz=rx/rl,rz/rl
local ux,uy,uz=ry*fz-rz*fy,rz*fx-rx*fz,rx*fy-ry*fx
local qx,qy,qz=p[1]-ex,p[2]-ey,p[3]-ez
local depth=qx*fx+qy*fy+qz*fz;if depth<=.15 then return nil end
local x=qx*rx+qy*ry+qz*rz
local y=qx*ux+qy*uy+qz*uz
local t=math.tan((pose.fov or math.rad(40))*.5);if t<=.001 then return nil end
return x/(depth*t*cameraAspect()),y/(depth*t),depth
end
local function combatSubjects(arena,phase,side)
side=side or "player"
if phase=="attack" then return arenaPoint(arena,side,6.0),arenaPoint(arena,other(side),6.0) end
if phase=="damage" or phase=="reaction" or phase=="faint" then
return arenaPoint(arena,other(side),6.0),arenaPoint(arena,side,6.0)
end
if phase=="switch" then return arenaPoint(arena,side,6.0),arenaPoint(arena,other(side),6.0) end
end
local function subjectsReadable(pose,arena,phase,side)
local a,b=combatSubjects(arena,phase,side);if not a then return true end
local ax,ay,az=projectPose(pose,a);local bx,by,bz=projectPose(pose,b)
if not (ax and bx) then return false end
local xlim=(mobilePlatform() and .72 or .80)
local ylim=(mobilePlatform() and .58 or .70)
if math.abs(ax)>xlim or math.abs(bx)>xlim or math.abs(ay)>ylim or math.abs(by)>ylim then return false end
return az>4 and bz>4
end
local function anyCombatSubjectReadable(pose,arena,phase,side)
local a,b=combatSubjects(arena,phase,side);if not a then return true end
local function visible(p)
local x,y,z=projectPose(pose,p)
return x~=nil and math.abs(x)<.90 and math.abs(y)<.82 and z>3.2
end
return visible(a) or visible(b)
end
local function safeCombatMaster(arena,side,phase)
side=side or "player"
local attacker=(phase=="damage" or phase=="reaction" or phase=="faint") and other(side) or side
local a=arenaPoint(arena,attacker,6.0);local b=arenaPoint(arena,other(attacker),6.0)
local mid={(a[1]+b[1])*.5,6.0,(a[3]+b[3])*.5}
local dx,dz=b[1]-a[1],b[3]-a[3];local l=math.max(.001,math.sqrt(dx*dx+dz*dz))
local rx,rz=-dz/l,dx/l
local sign=actionAxisSide and actionAxisSide(arena,attacker) or (attacker=="player" and 1 or -1)
local distance=(phase=="damage" and 51 or 55)
return {eye={mid[1]+rx*distance*sign,23.0,mid[3]+rz*distance*sign},focus=mid,fov=math.rad(46)}
end
local function readabilityGuard(pose,arena,phase,side,sourceOwned)
if not pose then return pose end
local out=clampCameraVolume(pose,arena,phase)
if phase~="attack" and phase~="damage" and phase~="reaction" and phase~="faint" and phase~="switch" then return out end




local readable=sourceOwned and anyCombatSubjectReadable or subjectsReadable
if readable(out,arena,phase,side) then return out end


for _=1,3 do
local f=out.focus
out.eye={f[1]+(out.eye[1]-f[1])*1.12,f[2]+(out.eye[2]-f[2])*1.05,f[3]+(out.eye[3]-f[3])*1.12}
out.fov=math.min(math.rad(52),out.fov+math.rad(2.0))
out=clampCameraVolume(out,arena,phase)
if readable(out,arena,phase,side) then return out end
end
return clampCameraVolume(safeCombatMaster(arena,side,phase),arena,phase)
end
local function resetManual()
state.orbit=DEFAULT.orbit;state.elevation=DEFAULT.elevation;state.radius=DEFAULT.radius;state.fov=DEFAULT.fov
state.focus={DEFAULT.focus[1],DEFAULT.focus[2],DEFAULT.focus[3]}
state.mouseX=nil;state.mouseY=nil
end
local function isDown(key) return love and love.keyboard and love.keyboard.isDown and love.keyboard.isDown(key) and true or false end
local function pressed(key)
local d=isDown(key); local was=state.keys[key]; state.keys[key]=d
return d and not was
end
local function mouseDown(button)
return love and love.mouse and love.mouse.isDown and love.mouse.isDown(button) and true or false
end
local function battleOf(ctx)
if type(ctx)~="table" then return nil end
return ctx.battle or (ctx.kind and ctx) or nil
end
local function battleHash(ctx)
local b=battleOf(ctx)
local id=(b and b.trainer and (b.trainer.id or b.trainer.name)) or (b and b.oppClass) or (b and b.kind) or "battle"
local h=0
for i=1,#tostring(id) do h=(h*33+tostring(id):byte(i))%65521 end
return h
end
local function sideValue(value)
if value==nil then return nil end
if type(value)=="string" then
local key=value:lower()
if key=="player" or key=="ally" or key=="friendly" or key=="p1" then return "player" end
if key=="enemy" or key=="opponent" or key=="foe" or key=="p2" then return "enemy" end
local n=tonumber(value)
if n==1 then return "player" elseif n==2 then return "enemy" end
return nil
end
if type(value)=="number" then
if value==1 then return "player" elseif value==2 then return "enemy" end
return nil
end
if type(value)=="table" then


if type(value.isPlayer)=="boolean" then return value.isPlayer and "player" or "enemy" end
for _,k in ipairs({"side","index","id","name","team","ownerSide"}) do
local resolved=sideValue(value[k])
if resolved then return resolved end
end
end
return nil
end

local function sideFrom(ctx,payload,fields)
local b=battleOf(ctx)
if type(payload)~="table" then return nil end
for _,key in ipairs(fields or {"user","attacker","source","battler","side","target"}) do
local value=payload[key]
local resolved=sideValue(value)
if resolved then return resolved end
if b and value then
if value==b.player then return "player" end
if value==b.enemy then return "enemy" end
end
end
return nil
end
arenaPoint=function(arena,side,y)






local p=arena and ((side=="player" and arena.visualPlayer) or (side=="enemy" and arena.visualEnemy))
if not p and arena then p=arena[side] end
p=p or (side=="player" and {0,14.5} or {0,-14.5})
return {p[1] or 0,y or 6.5,p[2] or 0}
end
local function trainerPoint(side,y)
if side=="player" and PlayerTrainer and type(PlayerTrainer.anchor)=="function" then return PlayerTrainer:anchor(y) end
if side=="enemy" and Trainer and type(Trainer.anchor)=="function" then return Trainer:anchor(y) end
if side=="player" then return {13.2,y or 7.0,25.8} end
return {-13.2,y or 7.0,-25.8}
end
other=function(side) return side=="enemy" and "player" or "enemy" end
local function manualPose()
local r=state.radius; local ce=math.cos(state.elevation); local f=state.focus
return {
eye={f[1]+math.sin(state.orbit)*r*ce, f[2]+math.sin(state.elevation)*r, f[3]+math.cos(state.orbit)*r*ce},
focus={f[1],f[2],f[3]}, fov=math.rad(state.fov),
}
end

local function shotPose(s,u)
u=smooth(clamp(u or 0,0,1))
local tr=s.travel or {0,0,0}; local fr=s.focusTravel or {0,0,0}
local pose={
eye={s.eye[1]+tr[1]*u,s.eye[2]+tr[2]*u,s.eye[3]+tr[3]*u},
focus={s.focus[1]+fr[1]*u,s.focus[2]+fr[2]*u,s.focus[3]+fr[3]*u},
fov=math.rad(s.fov),
}



local arc=tonumber(s.arc) or 0
if math.abs(arc)>1e-7 then
local a=arc*u;local ca,sa=math.cos(a),math.sin(a)
local dx,dz=pose.eye[1]-pose.focus[1],pose.eye[3]-pose.focus[3]
pose.eye[1]=pose.focus[1]+dx*ca+dz*sa
pose.eye[3]=pose.focus[3]-dx*sa+dz*ca
end
return pose
end
local function hsdRandStep(seed)






seed=math.floor(tonumber(seed) or 1)%4294967296
local next=(seed*0x343FD+0x269EC3)%4294967296
local high=math.floor(next/65536)%65536
return next,high/65536
end
local function nextPassiveRandom()
local seed,value=hsdRandStep(state.passiveRng)
state.passiveRng=seed
return value
end
local function hsdRandBoundedStep(seed,range)
range=math.floor(tonumber(range) or 0)
if range<=0 then return seed,0 end


local seed1,a=hsdRandStep(seed)
local seed2,b=hsdRandStep(seed1)
local lo=math.floor(a*65536)
local hi=math.floor(b*65536)
return seed2,((hi*65536)+lo)%range
end
local function nextPassiveBounded(range)
local seed,value=hsdRandBoundedStep(state.passiveRng,range)
state.passiveRng=seed
return value
end
local PASSIVE_MOTIONS={3,0,1,2}
local function hsdSelectDifferentMotion(seed,lastMode)
local mode
repeat
local value;seed,value=hsdRandStep(seed)
local idx=math.min(#PASSIVE_MOTIONS,1+math.floor(value*#PASSIVE_MOTIONS))
mode=PASSIVE_MOTIONS[idx]
until mode~=lastMode
return seed,mode
end
local function hsdSelectDifferentBounded(seed,range,current)
range=math.floor(tonumber(range) or 0)
if range<=1 then return seed,0 end
local selected
repeat seed,selected=hsdRandBoundedStep(seed,range) until selected~=current
return seed,selected
end
local function choosePassiveMotion()





local seed,mode=hsdSelectDifferentMotion(state.passiveRng,state.passiveLastMotionMode)
state.passiveRng=seed
state.passiveMotionMode=mode
state.passiveLastMotionMode=state.passiveMotionMode
state.passiveSourcePlan=nil;state.passiveSourceTargetResolved=false
end
local function passiveCandidates(ctx)
local out={}
for i,s in ipairs(PASSIVE_SHOTS) do
local owner=s.owner or ""
if owner=="player-trainer" then
if trainerVisible and trainerVisible(ctx,"player") then out[#out+1]=i end
elseif owner=="enemy-trainer" then
if trainerVisible and trainerVisible(ctx,"enemy") then out[#out+1]=i end
else out[#out+1]=i end
end
if #out==0 then for i=1,#PASSIVE_SHOTS do out[#out+1]=i end end
return out
end
local function chooseDifferentPassiveShot(ctx)
local candidates=passiveCandidates(ctx);if #candidates<2 then return end
local current=tonumber(state.passiveShotIndex) or candidates[1]




local currentOrdinal=-1
for ordinal,i in ipairs(candidates) do if i==current then currentOrdinal=ordinal-1;break end end
local seed,selected=hsdSelectDifferentBounded(state.passiveRng,#candidates,currentOrdinal)
state.passiveRng=seed
state.passiveShotIndex=candidates[selected+1]
state.passiveShotAge=0
choosePassiveMotion()
end

local function passiveFovEnvelope(retail,sample,index)
if not (type(retail)=="table" and retail.exact==true and type(sample)=="table"
and type(sample.fovRange)=="table") then return nil end
index=math.max(1,math.min(3,math.floor(tonumber(index) or 1)))
local range=index==1 and tonumber(sample.fovRange.near)
or (index==2 and tonumber(sample.fovRange.mid) or tonumber(sample.fovRange.far))
if not range or range<=0 then return nil end
local scaleMin,scaleMax=tonumber(retail.scaleMin),tonumber(retail.scaleMax)



if index>=3 then scaleMin,scaleMax=scaleMax,tonumber(retail.rotationMin) end
if scaleMin==nil or scaleMax==nil then return nil end
local span=math.max(.75*scaleMin,scaleMax)
local low=math.deg(2*math.atan(.5*span/range))
local high=math.deg(2*math.atan(2*span/range))
low=clamp(low,15,85);high=clamp(high,15,85)
if high<low then low,high=high,low end
return low,high
end

local function buildPassiveFovPlan(retail,sample,timing)
local grammar=V and V.WazaCameraFov
if not (grammar and type(grammar.mixBand)=="function" and type(grammar.staticChoice)=="function"
and type(grammar.usesPattern)=="function") then return nil end
local function draw() return nextPassiveRandom() end
local function choose(flags,index)
local low,high=passiveFovEnvelope(retail,sample,index);if not low then return nil end
local a,b=grammar.mixBand(flags)
return low+(high-low)*(a+(b-a)*draw())
end
local motion=tonumber(sample and sample.mode)
if motion==nil then return nil end
if not grammar.usesPattern(motion) then
local value=choose(grammar.staticChoice(4),1);if not value then return nil end
return {initial=value,keys={},frame0=0,formulaExact=true,rngExact=false,timingExact=true,
patternUsed=false}
end
if not (type(timing)=="table" and timing.exact==true and tonumber(timing.sequenceKind)
and type(timing.frames)=="table" and type(grammar.selectPattern)=="function"
and type(grammar.selectDuration)=="function") then return nil end
local count=math.max(0,math.floor(tonumber(timing.count) or 0))
local shift=math.max(0,math.floor(tonumber(timing.frameShift) or 0));local scale=2^shift
local frame0=(tonumber(timing.frames[1]) or 0)*scale
local function randIndex(n)return nextPassiveBounded(math.max(1,n)) end




local row,rowIndex,tableName,selection=grammar.selectPattern(timing.sequenceKind,4,draw,randIndex)
if not (row and row.descriptors and row.descriptors[1]) then return nil end
local current=choose(row.descriptors[1].initialFlags,1);if not current then return nil end
local out={initial=current,keys={},frame0=frame0,formulaExact=true,rngExact=false,timingExact=true,
patternUsed=true,rowIndex=rowIndex,tableName=tableName,selection=selection}
if count<=2 then return out end
local prev=tonumber(timing.frames[1]) or 0
for i=1,2 do
local nextFrame=tonumber(timing.frames[i+1]) or prev
local desc=row.descriptors[i]
local key={start=current,finish=current,startFrame=prev*scale,endFrame=nextFrame*scale}
if desc and prev~=nextFrame and tonumber(desc.mode) and desc.mode>=3 and desc.mode<5 then
local duration=grammar.selectDuration(desc.durationMode,desc.thresholds,nextFrame-prev,draw)
local ending=choose(desc.flags or 0,i+1);if not ending then return nil end
key.finish=ending
if desc.timingMode==2 then key.startFrame=(nextFrame-duration)*scale;key.endFrame=nextFrame*scale
else key.startFrame=prev*scale;key.endFrame=(prev+duration)*scale end
current=ending
end
out.keys[i]=key;prev=nextFrame
end
return out
end

local function passiveFovAt(plan,age)
local fp=plan and plan.fovPlan;if not fp then return nil end
local clock=(tonumber(fp.frame0) or 0)+math.max(0,tonumber(age) or 0)*60
local value=tonumber(fp.initial)
for _,key in ipairs(fp.keys or {}) do
if clock<=key.startFrame then value=key.start;break end
if clock<=key.endFrame then
local span=key.endFrame-key.startFrame
local t=span>0 and (clock-key.startFrame)/span or 1
value=key.start+(key.finish-key.start)*clamp(t,0,1);break
end
value=key.finish
end
return value and math.rad(value) or nil
end

local function passivePokemonSourcePlan(ctx,s)
local owner=tostring(s and s.owner or "")
local side=owner=="player-pokemon" and "player" or (owner=="enemy-pokemon" and "enemy" or nil)
if not side then return nil end
local models=CurrentSpriteModels or (V and V.CurrentSpriteModels)
local params=V and V.WazaCameraParams
if not (models and type(models.wazaBasis)=="function" and params and type(params.calculate)=="function"
and type(params.sampleMotion)=="function") then return nil end
local otherSide=side=="player" and "enemy" or "player"
local ok,root=pcall(models.wazaBasis,models,ctx,side,otherSide,nil,{
role="attack",sourceStrict=true,ownerRoot=true})
if not ok or type(root)~="table" or root.ownerModelRotationExact~=true then return nil end
local selector=tonumber(root.sourceScaleSelector)
local yaw=tonumber(root.ownerModelYaw)
if selector==nil or yaw==nil then return nil end
local retail=params.calculate(4,selector,root.ownerRetailWazaBound,yaw)
if not (type(retail)=="table" and retail.exact==true) then return nil end
local mode=tonumber(state.passiveMotionMode)
local key=table.concat({tostring(state.passiveShotIndex),tostring(mode),side,tostring(selector),string.format("%.7f",yaw)},":")
if state.passiveSourcePlan and state.passiveSourcePlan.key==key then return state.passiveSourcePlan end



local sample=params.sampleMotion(mode,retail,function()return nextPassiveRandom() end,{
rotationBase=yaw,reverse=side=="player",
})
if not (type(sample)=="table" and sample.worldRotationFormulaExact==true
and tonumber(sample.worldRotation0) and tonumber(sample.worldRotation1)) then return nil end
local timing=root.ownerCameraTiming
local durationSeconds,durationExact
if type(timing)=="table" and timing.motionDurationExact==true and tonumber(timing.motionDurationFrames) then
local shift=math.max(0,math.floor(tonumber(timing.frameShift) or 0))
local rate=math.max(1,tonumber(timing.rate) or 60)
if mode~=0 then
durationSeconds=math.max(0,tonumber(timing.motionDurationFrames))*(2^shift)/rate
durationExact=true
end
end
local plan={key=key,side=side,otherSide=otherSide,selector=selector,ownerYaw=yaw,
reverse=side=="player",sample=sample,angleFormulaExact=true,angleRngExact=false,
forward=type(root.forward)=="table" and copy3(root.forward) or nil,
right=type(root.right)=="table" and copy3(root.right) or nil,
targetField="pkx-current-slot+0x54/chest",targetFieldExact=true,
physicalFormulaExact=true,radiusAbsoluteExact=false,
durationSeconds=durationSeconds,durationExact=durationExact==true,fovExact=false}
plan.fovPlan=buildPassiveFovPlan(retail,sample,timing)
plan.fovFormulaExact=plan.fovPlan and plan.fovPlan.formulaExact==true or false
plan.fovRngExact=plan.fovPlan and plan.fovPlan.rngExact==true or false
plan.fovTimingExact=plan.fovPlan and plan.fovPlan.timingExact==true or false
state.passiveSourcePlan=plan
return plan
end

local function passivePokemonTarget(ctx,arena,plan)
if not plan then return nil end
local models=CurrentSpriteModels or (V and V.CurrentSpriteModels)
if not (models and type(models.wazaBasis)=="function") then return nil end



local ok,basis=pcall(models.wazaBasis,models,ctx,plan.side,plan.otherSide,2,{
role="attack",sourceStrict=true})
if not ok or type(basis)~="table" or type(basis.origin)~="table" then return nil end
local p=basis.origin
if not (tonumber(p[1]) and tonumber(p[2]) and tonumber(p[3])) then return nil end
local k=tonumber(arena and arena.figureScale) or tonumber(ctx and ctx.arena and ctx.arena.figureScale) or 1
return {p[1]*k,p[2]*k,p[3]*k}
end

local function passiveMotionPose(s,focus,age,sourcePlan,figureScale)
local duration=(sourcePlan and sourcePlan.durationExact and tonumber(sourcePlan.durationSeconds)) or s.hold or 1
local raw=clamp((tonumber(age) or 0)/math.max(.01,duration),0,1)
local u=smooth(raw);local fr=s.focusTravel or {0,0,0};local tr=s.travel or {0,0,0}
focus=focus or s.focus
if sourcePlan and sourcePlan.sample then
local sample=sourcePlan.sample
local sourceFov=passiveFovAt(sourcePlan,age) or math.rad(s.fov)








local k=tonumber(figureScale) or 1
local theta=(tonumber(sample.worldRotation0) or 0)+
((tonumber(sample.worldRotation1) or tonumber(sample.worldRotation0) or 0)-(tonumber(sample.worldRotation0) or 0))*raw
local distance=tonumber(sample.distance0)
if sample.mode==0 and distance and tonumber(sample.distance1) then
distance=distance+(sample.distance1-distance)*raw
end
local height=tonumber(sample.height)
if distance and height then
distance=distance*k;height=height*k
if sample.mode==1 and tonumber(sample.lateral0) and tonumber(sample.lateral1)
and type(sourcePlan.forward)=="table" and type(sourcePlan.right)=="table" then




local lateral=(sample.lateral0+(sample.lateral1-sample.lateral0)*raw)*k
local f,r=sourcePlan.forward,sourcePlan.right
return {eye={focus[1]-f[1]*distance+r[1]*lateral,
focus[2]+height,
focus[3]-f[3]*distance+r[3]*lateral},
focus={focus[1],focus[2],focus[3]},fov=sourceFov}
end
if tonumber(sample.worldRotation0) and tonumber(sample.worldRotation1) then
return {eye={focus[1]+math.sin(theta)*distance,focus[2]+height,focus[3]+math.cos(theta)*distance},
focus={focus[1],focus[2],focus[3]},fov=sourceFov}
end
end
end
local f={focus[1]+fr[1]*u,focus[2]+fr[2]*u,focus[3]+fr[3]*u}
local eye={s.eye[1],s.eye[2],s.eye[3]}
local mode=state.passiveMotionMode
if mode==3 then



eye={eye[1]+tr[1]*u,eye[2]+tr[2]*u,eye[3]+tr[3]*u}
elseif mode==0 then



local dx,dz=eye[1]-f[1],eye[3]-f[3];local k=1+(tonumber(s.dolly) or .10)*u
eye[1]=f[1]+dx*k;eye[3]=f[3]+dz*k
elseif mode==1 then



local dx,dz=eye[1]-f[1],eye[3]-f[3];local l=math.max(.001,math.sqrt(dx*dx+dz*dz))
local sign=(tonumber(s.arc) or 0)<0 and -1 or 1;local lateral=(tonumber(s.lateral) or 9)*u*sign
eye[1]=eye[1]-dz/l*lateral;eye[3]=eye[3]+dx/l*lateral
elseif mode==2 then


local a=(tonumber(s.arc) or 0)*u;local ca,sa=math.cos(a),math.sin(a)
local dx,dz=eye[1]-f[1],eye[3]-f[3]
eye[1]=f[1]+dx*ca+dz*sa;eye[3]=f[3]-dx*sa+dz*ca
end
return {eye=eye,focus=f,fov=math.rad(s.fov)}
end
local function passiveFloorSettle(pose,age,duration,shotIndex)
local elapsed=(tonumber(age) or 0)-math.max(0,tonumber(duration) or 0)
if elapsed<=0 or not (pose and pose.eye and pose.focus) then return pose,false,false end
local raw=clamp(elapsed/PASSIVE_FLOOR_SETTLE_DURATION,0,1)
local u=smooth(raw)
local dx,dz=pose.focus[1]-pose.eye[1],pose.focus[3]-pose.eye[3]
local len=math.sqrt(dx*dx+dz*dz)
if len<.001 then return pose,true,false end




local rx,rz=-dz/len,dx/len
local sign=((tonumber(shotIndex) or 1)%2==0) and -1 or 1
local shift=PASSIVE_FLOOR_SETTLE_DISTANCE*u*sign
local out=copyPose(pose)
out.eye[1]=out.eye[1]+rx*shift;out.eye[3]=out.eye[3]+rz*shift
out.focus[1]=out.focus[1]+rx*shift;out.focus[3]=out.focus[3]+rz*shift
return out,true,raw<1
end
local function passiveShot(ctx,arena)
local s=PASSIVE_SHOTS[state.passiveShotIndex] or PASSIVE_SHOTS[1]
if not s then return manualPose() end
local owner=s.owner or "";local p
local sourcePlan=passivePokemonSourcePlan(ctx,s)
if sourcePlan then p=passivePokemonTarget(ctx,arena,sourcePlan) end
state.passiveSourceTargetResolved=p~=nil and sourcePlan~=nil
if not p and owner=="player-pokemon" then p=arenaPoint(arena,"player",6.0)
elseif not p and owner=="enemy-pokemon" then p=arenaPoint(arena,"enemy",6.0)
elseif owner=="player-trainer" then p=trainerPoint("player",6.8)
elseif owner=="enemy-trainer" then p=trainerPoint("enemy",6.8) end



local figureScale=tonumber(arena and arena.figureScale) or tonumber(ctx and ctx.arena and ctx.arena.figureScale) or 1
local duration=(sourcePlan and sourcePlan.durationExact and tonumber(sourcePlan.durationSeconds)) or s.hold or 1
local pose=passiveMotionPose(s,p,state.passiveShotAge,sourcePlan,figureScale)
pose,state.passiveFloorFallbackActive,state.passiveFloorFallbackMoving=
passiveFloorSettle(pose,state.passiveShotAge,duration,state.passiveShotIndex)
return pose
end

trainerVisible=function(ctx,side)
local provider=side=="player" and PlayerTrainer or Trainer
if not (provider and type(provider.shouldRender)=="function") then return false end
local ok,v=pcall(provider.shouldRender,provider,ctx)
return ok and v==true
end

local function trainerPassiveMaster(ctx)




local hasPlayer=trainerVisible(ctx,"player")
local hasEnemy=trainerVisible(ctx,"enemy")
if not (hasPlayer or hasEnemy) then return nil end



local idx=((state.shotOffset or 0)%#COMMAND_SHOTS)+1
local s=COMMAND_SHOTS[idx] or COMMAND_SHOTS[1]
local shot=shotPose(s,math.min(1,state.idleClock/math.max(.01,s.hold or 1)))
if hasEnemy and not hasPlayer then
shot.focus={-2.0,5.9,-3.5}
elseif hasPlayer and not hasEnemy then
shot.focus={2.0,5.9,3.5}
end
return shot
end

actionAxisSide=function(arena,attackerSide)
attackerSide=attackerSide or "player"
if state.actionAxisAttacker==attackerSide and state.actionAxisSign then return state.actionAxisSign end
local src=arenaPoint(arena,attackerSide,6.0)
local dst=arenaPoint(arena,other(attackerSide),6.0)
local dx,dz=dst[1]-src[1],dst[3]-src[3]
local len=math.max(.001,math.sqrt(dx*dx+dz*dz));local rx,rz=-dz/len,dx/len
local midx,midz=(src[1]+dst[1])*.5,(src[3]+dst[3])*.5
local reference=state.startPose or state.lastPose
local dot=reference and ((reference.eye[1]-midx)*rx+(reference.eye[3]-midz)*rz) or 0
local sign
if math.abs(dot)>.001 then sign=dot<0 and -1 or 1
else sign=attackerSide=="player" and 1 or -1 end
state.actionAxisAttacker=attackerSide;state.actionAxisSign=sign
return sign
end
local function actionAxisPose(arena,attackerSide,focus,range,back,side,lift,fov)
local src=arenaPoint(arena,attackerSide,6.0)
local dst=arenaPoint(arena,other(attackerSide),6.0)
local dx,dz=dst[1]-src[1],dst[3]-src[3]
local len=math.max(.001,math.sqrt(dx*dx+dz*dz));local fx,fz=dx/len,dz/len
local rx,rz=-fz,fx;local sign=actionAxisSide(arena,attackerSide)
range=math.max(24,tonumber(range) or len*1.45)
return {eye={focus[1]-fx*range*(back or .2)+rx*range*(side or .7)*sign,
focus[2]+range*(lift or .22),focus[3]-fz*range*(back or .2)+rz*range*(side or .7)*sign},
focus=focus,fov=fov or math.rad(42)}
end


local function eventShot(ctx,arena,side,kind,variant)
side=side or "player"; variant=((variant or 1)-1)%3+1
local a=arenaPoint(arena,side,6.2); local sgn=side=="player" and 1 or -1
local z=a[3]
if kind=="attack" then




local target=arenaPoint(arena,other(side),6.1)
local focus={a[1]*.72+target[1]*.28,6.15,a[3]*.72+target[3]*.28}
local fight=math.max(28,math.sqrt((target[1]-a[1])^2+(target[3]-a[3])^2)*1.48)
if variant==1 then return actionAxisPose(arena,side,focus,fight,.22,.82,.34,math.rad(45)) end
if variant==2 then return actionAxisPose(arena,side,focus,fight,.06,.88,.32,math.rad(45)) end
return actionAxisPose(arena,side,focus,fight,.34,.74,.36,math.rad(46))
elseif kind=="damage" then




local attackerSide=other(side)
local attacker=arenaPoint(arena,attackerSide,6.1)
local focus={a[1]*.76+attacker[1]*.24,6.00,a[3]*.76+attacker[3]*.24}
local fight=math.max(27,math.sqrt((a[1]-attacker[1])^2+(a[3]-attacker[3])^2)*1.40)
if variant==1 then return actionAxisPose(arena,attackerSide,focus,fight,.10,.75,.30,math.rad(43)) end
if variant==2 then return actionAxisPose(arena,attackerSide,focus,fight,-.02,.80,.29,math.rad(43)) end
return actionAxisPose(arena,attackerSide,focus,fight,.20,.69,.32,math.rad(44))
elseif kind=="reaction" then



local hasTrainer=trainerVisible(ctx,side)
local tp=hasTrainer and trainerPoint(side,7.0) or a
local midx=hasTrainer and (a[1]*.68+tp[1]*.32) or a[1]
local midz=hasTrainer and (a[3]*.68+tp[3]*.32) or a[3]
local attackerSide=other(side);local focus={midx,6.05,midz}
local attacker=arenaPoint(arena,attackerSide,6.0)
local fight=math.max(25,math.sqrt((a[1]-attacker[1])^2+(a[3]-attacker[3])^2)*1.30)
if variant==1 then return actionAxisPose(arena,attackerSide,focus,fight,.02,.66,.27,math.rad(hasTrainer and 37 or 34)) end
if variant==2 then return actionAxisPose(arena,attackerSide,focus,fight,.13,.62,.29,math.rad(hasTrainer and 37 or 34)) end
return actionAxisPose(arena,attackerSide,focus,fight,-.08,.70,.30,math.rad(hasTrainer and 38 or 35))
elseif kind=="capture" then
local target=arenaPoint(arena,"enemy",6.0); local hasTrainer=trainerVisible(ctx,"player")
local tp=hasTrainer and trainerPoint("player",7.0) or target
local status
if PlayerTrainer and type(PlayerTrainer.captureStatus)=="function" then
local ok,v=pcall(PlayerTrainer.captureStatus,PlayerTrainer,ctx)
if ok and type(v)=="table" and v.active then status=v end
end
local phase=status and status.phase or "charge"
local u=math.max(0,math.min(1,tonumber(status and status.progress) or 0))
local liveBall=nil
if PlayerTrainer and type(PlayerTrainer.captureBallPosition)=="function" then
local ok,v=pcall(PlayerTrainer.captureBallPosition,PlayerTrainer,ctx)
if ok and type(v)=="table" and tonumber(v[1]) and tonumber(v[2]) and tonumber(v[3]) then liveBall=v end
end



local dx,dz=target[1]-tp[1],target[3]-tp[3]
local len=math.max(.001,math.sqrt(dx*dx+dz*dz));local fx,fz=dx/len,dz/len
local rx,rz=-fz,fx
local function eyeAt(point,back,side,y)
return {point[1]-fx*back+rx*side,y,point[3]-fz*back+rz*side}
end
local function focusAt(point,y)
return {point[1],y,point[3]}
end





local ball=liveBall or target
if phase=="charge" then


return {eye=eyeAt(tp,5.9,7.8,8.4),focus={ball[1],ball[2]+.05,ball[3]},fov=math.rad(31)}
elseif phase=="throw" then
local lead={ball[1]+fx*1.65,ball[2]-.10,ball[3]+fz*1.65}




local trackU=.30+.34*u
local track={tp[1]+dx*trackU,6.0,tp[3]+dz*trackU}
return {eye=eyeAt(track,7.9,10.0,8.45),focus=lead,fov=math.rad(34)}
elseif phase=="impact" then
return {eye=eyeAt(target,13.2,-8.0,8.7),focus={ball[1],ball[2],ball[3]},fov=math.rad(29)}
elseif phase=="absorb" then
return {eye=eyeAt(target,11.8,-6.8,7.8),focus={ball[1],ball[2]-.10,ball[3]},fov=math.rad(28)}
elseif phase=="fall" then
return {eye=eyeAt(ball,8.6,7.0,5.0),focus={ball[1],ball[2]-.18,ball[3]},fov=math.rad(27)}
elseif phase=="settle" then
return {eye=eyeAt(ball,7.4,6.3,3.25),focus={ball[1],ball[2]+.06,ball[3]},fov=math.rad(25)}
elseif phase=="shake" then




local ground={target[1],.31,target[3]}
return {eye=eyeAt(ground,5.35,4.55,2.42),focus={ground[1],ground[2]+.08,ground[3]},fov=math.rad(22)}
elseif phase=="caught" then
return {eye=eyeAt(ball,7.4,5.8,3.7),focus={ball[1],ball[2]+.04,ball[3]},fov=math.rad(26)}
elseif phase=="breakout" then



local ground={target[1],.31,target[3]}
if u<.42 then
return {eye=eyeAt(ground,7.2,5.8,3.15),focus={ground[1],ground[2]+.18,ground[3]},fov=math.rad(26)}
end
local q=smooth((u-.42)/.58)
local focus={ground[1]+(target[1]-ground[1])*q,.55+(5.15-.55)*q,ground[3]+(target[3]-ground[3])*q}
return {eye=eyeAt(target,10.6,-7.1,6.9),focus=focus,fov=math.rad(29)}
end
return {eye=eyeAt(target,12,8,8),focus=focusAt(target,4),fov=math.rad(30)}
elseif kind=="faint" then



local hasTrainer=trainerVisible(ctx,side)
local tp=hasTrainer and trainerPoint(side,6.9) or a
local focusBias=hasTrainer and .62 or 0
local midx=tp[1]*focusBias+a[1]*(1-focusBias)
local midz=tp[3]*focusBias+a[3]*(1-focusBias)
if variant==1 then return {eye={-sgn*(hasTrainer and 28 or 36),15,sgn*8},focus={midx,6.15,midz},fov=math.rad(hasTrainer and 37 or 41)} end
if variant==2 then return {eye={sgn*(hasTrainer and 25 or 34),15,sgn*10},focus={midx,6.0,midz},fov=math.rad(hasTrainer and 38 or 41)} end
return {eye={-sgn*(hasTrainer and 21 or 38),18,sgn*5},focus={midx,6.0,midz},fov=math.rad(hasTrainer and 39 or 42)}
elseif kind=="switch" then
local hasTrainer=trainerVisible(ctx,side)
local tp=hasTrainer and trainerPoint(side,7.0) or a
local midx=hasTrainer and (tp[1]+a[1])*.5 or a[1]
local midz=hasTrainer and (tp[3]+a[3])*.5 or a[3]
if variant==1 then return {eye={-sgn*(hasTrainer and 33 or 39),16,sgn*8},focus={midx,6.2,midz},fov=math.rad(hasTrainer and 40 or 44)} end
if variant==2 then return {eye={sgn*(hasTrainer and 30 or 38),16,sgn*11},focus={midx,6.3,midz},fov=math.rad(hasTrainer and 40 or 44)} end
return {eye={-sgn*(hasTrainer and 25 or 40),14,sgn*4},focus={midx,5.9,midz},fov=math.rad(hasTrainer and 41 or 45)}
end
return {eye={46,20,z+sgn*8},focus={a[1],6,z},fov=math.rad(37)}
end




local function liveSendoutShot(ctx,arena,requestedSide)
local chosen,side
for _,row in ipairs({{Trainer,"enemy"},{PlayerTrainer,"player"}}) do
local actor=row[1]
if (not requestedSide or row[2]==requestedSide) and actor and type(actor.sendoutStatus)=="function" then
local ok,status=pcall(actor.sendoutStatus,actor)
if ok and status and status.active and (not chosen or status.age<chosen.age) then chosen,side=status,row[2] end
end
end
if not chosen then return nil end
local pose=eventShot(ctx,arena,side,"switch",1)
if chosen.ball then
local tp=trainerPoint(side,6.6)
local u=math.max(0,math.min(1,(chosen.phase-.31)/.48))

pose.focus={tp[1]+(chosen.ball[1]-tp[1])*u,tp[2]+(chosen.ball[2]-tp[2])*u,tp[3]+(chosen.ball[3]-tp[3])*u}
end
return pose,side
end


function C:sendoutShot(ctx,arena,side)
local pose=liveSendoutShot(ctx,arena,side)
return pose and clampCameraVolume(hudSafePose(pose,"switch"),arena,"switch") or nil
end
function C:guardPose(pose,arena,phase)



return clampCameraVolume(hudSafePose(pose,phase),arena,phase)
end
function C:guardFreePose(pose,arena)
return clampCameraVolume(pose,arena,"free")
end


function C:guardPacedPose(pose,arena)
return clampCameraVolume(pose,arena,"attack")
end

local function introShot(ctx)
local hasEnemy=Trainer and Trainer.shouldRender and Trainer:shouldRender(ctx)
local hasPlayer=PlayerTrainer and PlayerTrainer.shouldRender and PlayerTrainer:shouldRender(ctx)
local establish={eye={64,39,27},focus={0,6.1,-1},fov=math.rad(44)}
local et=trainerPoint("enemy",6.6); local pt=trainerPoint("player",6.6)
local enemy=hasEnemy and {eye={35,24,et[3]-15.5},focus={et[1]*0.66,6.5,et[3]+5.4},fov=math.rad(39)}
or {eye={-47,27,-27},focus={0,6.4,-8},fov=math.rad(39)}
local player=hasPlayer and {eye={-35,24,pt[3]+15.5},focus={pt[1]*0.66,6.5,pt[3]-5.4},fov=math.rad(39)}
or {eye={49,27,27},focus={0,6.4,8},fov=math.rad(39)}
local battle={eye={62,29,3},focus={0,6.3,0},fov=math.rad(39)}
local t=state.phaseAge
if t<0.78 then
local drift={eye={48,36,44},focus={0,6.25,-1},fov=math.rad(43)}
return mix(establish,drift,t/0.78)
elseif t<1.48 then
return mix({eye={48,36,44},focus={0,6.25,-1},fov=math.rad(43)},enemy,(t-0.78)/0.70)
elseif t<1.98 then
return enemy
elseif t<2.72 then
return mix(enemy,player,(t-1.98)/0.74)
elseif t<3.18 then
return player
elseif t<3.92 then
return mix(player,battle,(t-3.18)/0.74)
end
return battle
end

local function exitShot(ctx,arena,result)
result=tostring(result or ""):lower()
local player=arenaPoint(arena,"player",6.2); local enemy=arenaPoint(arena,"enemy",6.2)
if result=="lose" or result=="loss" or result=="defeat" then
local hasTrainer=trainerVisible(ctx,"enemy")
if not hasTrainer then



return {eye={46,19,-28},focus={(player[1]+enemy[1])*.5,5.9,(player[3]+enemy[3])*.5},fov=math.rad(45)}
end
local tp=trainerPoint("enemy",7.0)
return {eye={38,19,-32},focus={(tp[1]+enemy[1])*.5,6.2,(tp[3]+enemy[3])*.5},fov=math.rad(40)}
elseif result=="run" or result=="escape" then
return {eye={55,25,18},focus={player[1],5.8,player[3]-5},fov=math.rad(42)}
elseif result=="caught" or result=="capture" or result=="captured" then
return {eye={42,20,18},focus={enemy[1],5.9,enemy[3]},fov=math.rad(40)}
end
local hasTrainer=trainerVisible(ctx,"player")
if not hasTrainer then
return {eye={-46,19,28},focus={(player[1]+enemy[1])*.5,5.9,(player[3]+enemy[3])*.5},fov=math.rad(45)}
end
local tp=trainerPoint("player",7.0)
return {eye={-38,19,32},focus={(tp[1]+player[1])*.5,6.2,(tp[3]+player[3])*.5},fov=math.rad(40)}
end

local function targetFor(ctx,phase,base,arena)
if state.manual then return manualPose() end
local side=state.eventSide
local pose
local speed=battleSpeed(ctx)
if phase=="attack" then pose=eventShot(ctx,arena,side or "player","attack",state.eventIndex)
elseif phase=="damage" then pose=eventShot(ctx,arena,side or "enemy","damage",state.eventIndex)
elseif phase=="reaction" then pose=eventShot(ctx,arena,side or "enemy","reaction",state.eventIndex)
elseif phase=="capture" then pose=eventShot(ctx,arena,"enemy","capture",state.eventIndex)
elseif phase=="faint" then pose=eventShot(ctx,arena,side or "enemy","faint",state.eventIndex)
elseif phase=="intro" then pose=introShot(ctx)
elseif phase=="exit" then pose=exitShot(ctx,arena,state.eventResult)
elseif phase=="switch" or (state.special=="switch" and state.time<state.specialUntil) then
pose=eventShot(ctx,arena,side or "player","switch",state.eventIndex)
elseif phase=="command" then
pose=trainerPassiveMaster(ctx) or shotPose(COMMAND_SHOTS[((state.shotOffset or 0)%#COMMAND_SHOTS)+1],1)
elseif phase=="passive" then
pose=passiveShot(ctx,arena)
else
pose=passiveShot(ctx,arena)
end







if phase=="passive" and state.passiveSourcePlan
and state.passiveSourcePlan.physicalFormulaExact==true
and state.passiveSourceTargetResolved==true then




if state.passiveSourcePlan.fovFormulaExact==true then return pose end
return widenAuthored(pose)
end
return widenAuthored(arenaFrame(pose,arena))
end

local function touchManual()
if not state.manual then
state.manual=true;state.startPose=copyPose(state.lastPose);state.phaseAge=0
end
state.manualIdle=0;state.returning=false
end
local function releaseManual()
if not state.manual then return end
state.manual=false;state.manualIdle=0;state.startPose=copyPose(state.lastPose);state.phaseAge=0;state.returning=true
state.mouseX=nil;state.mouseY=nil
end
local function updateMouse()
if not (love and love.mouse and love.mouse.getPosition) then state.mouseX=nil;state.mouseY=nil;return false end
local x,y=love.mouse.getPosition()
if state.mouseX==nil then state.mouseX=x;state.mouseY=y;return false end
local dx,dy=x-state.mouseX,y-state.mouseY;state.mouseX,state.mouseY=x,y
if dx==0 and dy==0 then return false end
local dragging=mouseDown(1) or mouseDown(2) or mouseDown(3)
if not dragging then return false end
touchManual()
if mouseDown(1) then
state.orbit=state.orbit-dx*0.0075;state.elevation=state.elevation-dy*0.0058
elseif mouseDown(2) then
if isDown("lshift") or isDown("rshift") then state.fov=state.fov+dy*0.12 else state.radius=state.radius+dy*0.28 end
elseif mouseDown(3) then
local pan=state.radius*0.0025;local rx,rz=math.cos(state.orbit),-math.sin(state.orbit);local fx,fz=math.sin(state.orbit),math.cos(state.orbit)
state.focus[1]=state.focus[1]-dx*pan*rx+dy*pan*0.18*fx;state.focus[3]=state.focus[3]-dx*pan*rz+dy*pan*0.18*fz;state.focus[2]=state.focus[2]+dy*0.025
end
return true
end
local function keyboardCameraActive()
return isDown("j") or isDown("l") or isDown("i") or isDown("k") or isDown("u") or isDown("o") or isDown("n") or isDown("m")
end
local function clampManual()
state.elevation=clamp(state.elevation,0.08,1.16);state.radius=clamp(state.radius,26,135);state.fov=clamp(state.fov,22,74)
state.focus[1]=clamp(state.focus[1],-42,42);state.focus[2]=clamp(state.focus[2],1.5,22);state.focus[3]=clamp(state.focus[3],-42,42)
end

local function requestedPhase(name,ctx)
if name=="battle.move_used" or name=="battle.presentation_move" then return "attack" end
if name=="battle.damage_dealt" or name=="battle.presentation_damage" then return "damage" end
if name=="battle.status_inflicted" then return "reaction" end
if name=="battle.ball_thrown" then return "capture" end
if name=="battle.exp_gained" then return nil end
if name=="battle.fainted" or name=="battle.presentation_faint" then return "faint" end
if name=="battle.battler_switched" then return "switch" end
if name=="battle.turn_started" or name=="battle.turn_ended" then return "passive" end
if name=="battle.ended" then return "exit" end
local p=ctx and ctx.phase
if p=="intro" or p=="command" or p=="passive" or p=="exit" then return p end
return state.phase
end

local function eventSideFor(ctx,name,payload)




if name=="battle.move_used" or name=="battle.presentation_move" then
return sideFrom(ctx,payload,{"user","attacker","source","battler","side"})
elseif name=="battle.damage_dealt" or name=="battle.presentation_damage" then
local target=sideFrom(ctx,payload,{"target","defender","targetSide","defenderSide","battler"})
if target then return target end
local actor=sideFrom(ctx,payload,{"user","attacker","source","side"})
return actor and other(actor) or nil
elseif name=="battle.status_inflicted" then
return sideFrom(ctx,payload,{"target","battler","side","targetSide","source"})
elseif name=="battle.ball_thrown" then
return "enemy"
elseif name=="battle.fainted" or name=="battle.presentation_faint" then
return sideFrom(ctx,payload,{"battler","target","side","faintedSide","targetSide"})
elseif name=="battle.battler_switched" then
return sideFrom(ctx,payload,{"side","battler","target","switchedSide"})
end
return sideFrom(ctx,payload)
end

local function acceptEvent(ev)
if not ev then return end
local previousPhase=state.phase
state.startPose=copyPose(state.lastPose)
state.phase=ev.phase or state.phase
state.phaseAge=0
if ev.side then state.eventSide=ev.side end



if state.phase=="attack" then
state.actionAxisAttacker=ev.side or state.eventSide or "player";state.actionAxisSign=nil
elseif state.phase=="damage" and previousPhase~="attack" then
state.actionAxisAttacker=other(ev.side or state.eventSide or "enemy");state.actionAxisSign=nil
elseif state.phase=="capture" or state.phase=="switch" or state.phase=="exit" then
state.actionAxisAttacker=nil;state.actionAxisSign=nil
end
if ev.indexed then



local continuation=(state.phase=="damage" and previousPhase=="attack")
or (state.phase=="reaction" and (previousPhase=="damage" or previousPhase=="attack"))
if not continuation then state.eventIndex=state.eventIndex+1 end
end
state.lastCutTime=state.time
state.lastEventName=ev.name
local speed=battleSpeed(ev.ctx)
state.logicSpeed=speed
state.shotLockUntil=state.time+(EVENT_HOLDS[state.phase] or 0.55)*holdScale(speed)
if state.phase=="switch" then
state.special="switch";state.specialUntil=state.shotLockUntil
end
end

local function queueEvent(ev)
local nextPriority=EVENT_PRIORITY[ev.phase] or 0
local age=state.time-state.lastCutTime






local impactBeat = ev.phase=="damage" and state.phase=="attack" and age>=0.72
local hardEnd = ev.phase=="exit" and age>=MIN_INTERRUPT_AGE
if impactBeat or hardEnd then
acceptEvent(ev)
state.pendingEvent=nil
return
end

local pending=state.pendingEvent
if not pending or nextPriority>(EVENT_PRIORITY[pending.phase] or 0)
or (nextPriority==(EVENT_PRIORITY[pending.phase] or 0) and ev.phase~="passive") then
state.pendingEvent=ev
end
end

function C:begin(ctx)
state.comfort=nil;state.comfortMaster=nil
state.time=0;state.idleClock=0;state.phaseAge=0;state.phase="intro";state.eventSide=nil;state.eventIndex=0;state.eventResult=nil;state.resultPending=nil;state.resultAt=0
state.lastPose=nil;state.startPose=nil;state.displayPose=nil;state.displayClock=nil;state.special=nil;state.specialUntil=0
state.presentInput=nil;state.displaySign=nil;state.floorScale=nil;state.floorScaleAt=nil
state.shotLockUntil=0;state.pendingEvent=nil;state.lastCutTime=-999;state.lastEventName=nil;state.logicSpeed=battleSpeed(ctx)
state.sourcePose=nil;state.sourceIdentity=nil;state.sourcePoseAt=0;state.sourceHandoff=nil;state.sourceHandoffAt=0
state.actionAxisAttacker=nil;state.actionAxisSign=nil
local hash=battleHash(ctx);state.shotOffset=hash%#PASSIVE_SHOTS
local candidates=passiveCandidates(ctx)
state.passiveShotIndex=candidates[(hash%#candidates)+1] or 1
state.passiveShotAge=0;state.passiveTimer=PASSIVE_RANDOM_INTERVAL;state.passiveRng=hash+1
state.passiveSourcePlan=nil;state.passiveSourceTargetResolved=false
state.passiveFloorFallbackActive=false;state.passiveFloorFallbackMoving=false


state.passiveMotionMode=PASSIVE_MOTIONS[(hash%#PASSIVE_MOTIONS)+1]
state.passiveLastMotionMode=state.passiveMotionMode
state.manual=false;state.manualLocked=false;state.manualIdle=0;state.returning=false;resetManual()
end
function C:update(ctx,dt)
local gen3Faint=V.Gen3Presentation and V.Gen3Presentation.session
and V.Gen3Presentation.session.screen==ctx.battle and V.Gen3Presentation.faintActive()
dt=tonumber(dt) or 0
if dt~=dt or math.abs(dt)==math.huge then dt=0 end
local speed=battleSpeed(ctx)
state.logicSpeed=speed



local cameraDt=math.max(0,math.min(.25,dt))
state.frameDriven=ctx.services and ctx.services.cameraFrameClock==true or false
if Pacing and not state.frameDriven then cameraDt=cameraDt/speed end
state.time=state.time+cameraDt
state.phaseAge=state.phaseAge+cameraDt






local b=battleOf(ctx)
local result=b and b.result
if result~=nil then result=tostring(result):lower() end
if result and result~="" and result~=state.eventResult and result~=state.resultPending then
state.resultPending=result
local faintInFlight=state.phase=="faint"
or (state.pendingEvent and state.pendingEvent.phase=="faint")


local resultDelay=faintInFlight and 1.35 or 0.22
if faintInFlight and BattleDirector and type(BattleDirector.faintDuration)=="function" then
local side=(state.pendingEvent and state.pendingEvent.phase=="faint" and state.pendingEvent.side) or state.eventSide
local ok,fd=pcall(BattleDirector.faintDuration,BattleDirector,ctx,side)
if ok and tonumber(fd) then



resultDelay=math.max(resultDelay,tonumber(fd)+.10)
end
end


state.resultAt=state.time+resultDelay
end





if state.phase=="intro" and state.phaseAge>=4.20 then
state.startPose=copyPose(state.lastPose)
state.phase="passive";state.phaseAge=0;state.idleClock=0
state.lastCutTime=state.time;state.lastEventName="intro.complete";state.shotLockUntil=0
end
if state.phase=="passive" then
state.idleClock=state.idleClock+cameraDt
state.passiveShotAge=state.passiveShotAge+cameraDt
local passive=PASSIVE_SHOTS[state.passiveShotIndex] or PASSIVE_SHOTS[1]
local duration=(state.passiveSourcePlan and state.passiveSourcePlan.durationExact
and tonumber(state.passiveSourcePlan.durationSeconds)) or (passive and passive.hold or 0)
local motionActive=passive and state.passiveShotAge<duration
if motionActive then




state.passiveTimer=PASSIVE_RANDOM_INTERVAL
else
state.passiveTimer=state.passiveTimer-cameraDt
if state.passiveTimer<=0 then


state.passiveTimer=PASSIVE_RANDOM_INTERVAL
if nextPassiveRandom()<=PASSIVE_RANDOM_GATE then chooseDifferentPassiveShot(ctx) end
end
end
elseif state.phase=="command" then
state.passiveFloorFallbackActive=false;state.passiveFloorFallbackMoving=false
state.idleClock=state.idleClock+cameraDt


state.passiveTimer=PASSIVE_RANDOM_INTERVAL
else
state.passiveFloorFallbackActive=false;state.passiveFloorFallbackMoving=false



state.passiveTimer=PASSIVE_RANDOM_INTERVAL
end
if state.special and state.time>=state.specialUntil then state.special=nil end
local captureStillActive=false
if state.phase=="capture" and PlayerTrainer and type(PlayerTrainer.captureStatus)=="function" then
local okCapture,captureStatus=pcall(PlayerTrainer.captureStatus,PlayerTrainer,ctx)
captureStillActive=okCapture and type(captureStatus)=="table" and captureStatus.active==true
end





local pendingBlockedByCapture=captureStillActive and state.pendingEvent
and state.pendingEvent.phase~="capture"
if state.pendingEvent and not gen3Faint and not pendingBlockedByCapture and state.time>=state.shotLockUntil and state.time>=(state.pendingEvent.notBefore or 0) then
local ev=state.pendingEvent;state.pendingEvent=nil;acceptEvent(ev)
elseif not gen3Faint and not captureStillActive and not state.pendingEvent and state.time>=state.shotLockUntil and state.shotLockUntil>0
and (state.phase=="attack" or state.phase=="damage" or state.phase=="reaction" or state.phase=="capture" or state.phase=="faint" or state.phase=="switch") then




state.startPose=copyPose(state.lastPose)
state.phase="passive";state.phaseAge=0;state.idleClock=0
state.lastCutTime=state.time;state.lastEventName="auto.return";state.shotLockUntil=0
end
if state.resultPending and state.time>=state.resultAt and not captureStillActive and not gen3Faint then
local committed=state.resultPending
state.resultPending=nil;state.eventResult=committed



if state.phase~="exit" then
state.pendingEvent=nil
acceptEvent({name="battle.result",phase="exit",side=nil,indexed=false,ctx=ctx})
end
end

if V.FreeLookCamera then state.manualLocked=false;releaseManual();return end
if pressed("f8") then
state.manualLocked=not state.manualLocked
if state.manualLocked then touchManual() else releaseManual() end
state.mouseX=nil;state.mouseY=nil
end
if pressed("home") then resetManual() end
local mouseMoved=updateMouse();local keyboardActive=keyboardCameraActive();if keyboardActive then touchManual() end
if state.manual then
local turn=1.35*cameraDt;local lift=0.90*cameraDt;local zoom=44*cameraDt;local lens=32*cameraDt
if isDown("j") then state.orbit=state.orbit-turn end;if isDown("l") then state.orbit=state.orbit+turn end
if isDown("i") then state.elevation=state.elevation+lift end;if isDown("k") then state.elevation=state.elevation-lift end
if isDown("u") then state.radius=state.radius-zoom end;if isDown("o") then state.radius=state.radius+zoom end
if isDown("n") then state.fov=state.fov-lens end;if isDown("m") then state.fov=state.fov+lens end
clampManual()
if state.manualLocked or mouseMoved or keyboardActive or mouseDown(1) or mouseDown(2) or mouseDown(3) then
state.manualIdle=0
else
state.manualIdle=state.manualIdle+cameraDt;if state.manualIdle>=MANUAL_RELEASE_DELAY then releaseManual() end
end
end
end
function C:event(ctx,name,payload)
if ctx.battle and ctx.battle.__cbeGeneration==3 then
if name=='battle.presentation_faint' or name=='battle.presentation_faint_complete'
or name=='battle.presentation_command' then
state.pendingEvent=nil;state.sourcePose=nil;state.sourceIdentity=nil;state.sourceHandoff=nil
acceptEvent({name=name,phase=name=='battle.presentation_faint' and 'faint'
or (name=='battle.presentation_command' and 'command' or 'passive'),
side=eventSideFor(ctx,name,payload),ctx=ctx})
return
end
end







local gen2=ctx and ctx.battle and ctx.battle.__cbeGeneration==2
local gen3Owned=ctx and ctx.battle and ctx.battle.__cbeGeneration==3
and V.Gen3Presentation and V.Gen3Presentation.session
and V.Gen3Presentation.session.screen==ctx.battle
local queueSync=ctx and ctx.battle and ctx.battle.__cbePresentationQueueSync==true
if queueSync and ((gen2 or gen3Owned) and
(name=="battle.move_used" or name=="battle.damage_dealt" or name=="battle.fainted")) then return end
if queueSync and name=="battle.fainted" then return end
local phase=requestedPhase(name,ctx)
if not phase then return end
local speed=battleSpeed(ctx)
state.logicSpeed=speed
if name=="battle.ended" and type(payload)=="table" then state.eventResult=payload.result or payload.outcome end



if not phaseAllowedAtSpeed(phase,speed) then return end





local indexed=name=="battle.move_used" or name=="battle.presentation_move"
or name=="battle.ball_thrown" or name=="battle.battler_switched"
local ev={name=name,phase=phase,side=eventSideFor(ctx,name,payload),indexed=indexed,ctx=ctx}



if phase=="faint" then
local delay=.32
if BattleDirector and type(BattleDirector.faintDuration)=="function" and ev.side then
local ok,fd=pcall(BattleDirector.faintDuration,BattleDirector,ctx,ev.side)
if ok and tonumber(fd) then delay=math.max(.14,math.min(.48,tonumber(fd)*.14)) end
end
ev.notBefore=state.time+delay
end





local captureOwnsLens=false
if phase=="exit" and PlayerTrainer and type(PlayerTrainer.captureStatus)=="function" then
local okCapture,captureStatus=pcall(PlayerTrainer.captureStatus,PlayerTrainer,ctx)
captureOwnsLens=okCapture and type(captureStatus)=="table" and captureStatus.active==true
end




if captureOwnsLens then
queueEvent(ev)
elseif state.time<state.shotLockUntil or (ev.notBefore and state.time<ev.notBefore) then
queueEvent(ev)
else
acceptEvent(ev)
end




if (name=="battle.damage_dealt" or name=="battle.presentation_damage") and ev.side and trainerVisible(ctx,ev.side) and type(payload)=="table" then
local damage=tonumber(payload.damage or payload.amount or payload.hpDamage) or 0
local target=payload.target or payload.defender or payload.battler
local mon=type(target)=="table" and (target.mon or target) or nil
local maxHp=mon and (tonumber(mon.maxHp) or tonumber(mon.maxHP) or (mon.stats and tonumber(mon.stats.hp))) or nil
if damage>0 and maxHp and maxHp>0 and damage/maxHp>=0.24 then
local reaction={name="battle.major_damage_reaction",phase="reaction",side=ev.side,indexed=false,notBefore=state.time+0.56,ctx=ctx}
local pending=state.pendingEvent
if not pending or (EVENT_PRIORITY[pending.phase] or 0)<=(EVENT_PRIORITY.reaction or 0) then state.pendingEvent=reaction end
end
end
end
function C:claim(ctx,phase)
return phase=="passive" or phase=="intro" or phase=="command" or phase=="attack" or phase=="damage" or phase=="reaction" or phase=="capture" or phase=="faint" or phase=="switch" or phase=="exit"
end
function C:shot(ctx,phase,progress,base,arena)
state.sourcePresentationClock=false
state.sourceExactLens=false
state.sourceBattlerId=nil
state.sourceRole=nil


local activePhase=state.phase
local target=targetFor(ctx,activePhase,base,arena);local pose




local sourcePhysicalPassive=activePhase=="passive" and state.passiveSourcePlan
and state.passiveSourcePlan.physicalFormulaExact==true
and state.passiveSourceTargetResolved==true
local sendoutTarget
if not state.manual and (activePhase=="intro" or activePhase=="switch" or activePhase=="passive" or activePhase=="command") then
sendoutTarget=liveSendoutShot(ctx,arena)
if sendoutTarget then target=sendoutTarget end
end




local wh=V and V.WazaHandlers
local sourceOwnsLens=false
local sourceExactLens=false
local gen3=V.Gen3Presentation and V.Gen3Presentation.session
local sourceSession=gen3 and gen3.screen==ctx.battle and gen3.movePresentation
if wh and type(wh.cameraPose)=="function" and not state.manual and (sourceSession or activePhase=="attack" or activePhase=="damage") then
local previousSource=state.sourcePose and copyPose(state.sourcePose) or nil
local mp=V.DoublesMovePresentation
local ok,sourcePose
if gen3 and gen3.screen==ctx.battle and mp and mp.sourceCameraPose then
ok,sourcePose=pcall(mp.sourceCameraPose,gen3)
else ok,sourcePose=pcall(wh.cameraPose,ctx) end
if ok and validSourcePose(sourcePose) then


if sourceSession then
activePhase=sourcePose.sourceRole=='damage' and 'damage' or 'attack'
sourcePhysicalPassive=false
end
local sourceRetailExact=sourcePose.sourceCameraEmbeddedDecoded==true
and sourcePose.sourceCameraRetailFrameExact==true
and sourcePose.sourceCameraEmbeddedTransformUnsupported==nil
local speed=battleSpeed(ctx)


sourceExactLens=sourceRetailExact
state.sourceExactLens=sourceRetailExact
state.sourcePresentationClock=sourcePose.sourceCameraPresentationClock==true
state.sourceBattlerId=sourcePose.cbeCameraBattlerId
state.sourceRole=sourcePose.sourceRole
target=stableSourcePose(sourcePose,sourceRetailExact or state.sourcePresentationClock,speed)
sourceOwnsLens=true
state.sourceHandoff=nil;state.sourceHandoffAt=0




else




if previousSource and not state.sourceHandoff then
state.sourceHandoff=previousSource;state.sourceHandoffAt=state.time
end
state.sourcePose=nil;state.sourceIdentity=nil;state.sourcePoseAt=state.time
end
else
if state.sourcePose and (activePhase=="attack" or activePhase=="damage") and not state.sourceHandoff then
state.sourceHandoff=copyPose(state.sourcePose);state.sourceHandoffAt=state.time
end
state.sourcePose=nil;state.sourceIdentity=nil;state.sourcePoseAt=state.time
end
do
local wanted=liveRetailFloorScale()
local current=tonumber(state.floorScale) or wanted
local dt=math.max(0,math.min(.1,state.time-(tonumber(state.floorScaleAt) or state.time)))
current=wanted+(current-wanted)*math.exp(-2.5*dt)
if math.abs(current-wanted)<1e-3 then current=wanted end
state.floorScale=current;state.floorScaleAt=state.time
local semantic=activePhase=="passive" or activePhase=="command" or activePhase=="attack"
or activePhase=="damage" or activePhase=="reaction" or activePhase=="faint"
if semantic and not state.manual and not sourceOwnsLens and not sourcePhysicalPassive and not sendoutTarget then
target=sizeClassDolly(target,current,0)
end
end




if not sourceExactLens and not sourcePhysicalPassive then
target=hudSafePose(target,activePhase)
if not (gen3 and gen3.screen==ctx.battle and V.Gen3BattleCamera) then
target=readabilityGuard(target,arena,activePhase,state.eventSide,sourceOwnsLens)
end
end
if state.manual then
if state.phaseAge<0.24 and state.startPose then pose=mix(state.startPose,target,state.phaseAge/0.24) else pose=target end
elseif state.returning then
pose=mix(state.startPose or base,target,state.phaseAge/AUTO_RETURN_BLEND);if state.phaseAge>=AUTO_RETURN_BLEND then state.returning=false end
elseif activePhase=="intro" then
pose=mix(state.startPose or base,target,state.phaseAge/0.34)
elseif activePhase=="passive" or activePhase=="command" then
if state.startPose and state.phaseAge<0.72 then pose=edit(state.startPose,target,state.phaseAge/0.72) else pose=target end
elseif sourceOwnsLens then
pose=target
elseif state.sourceHandoff and state.time-state.sourceHandoffAt<0.34 then



pose=edit(state.sourceHandoff,target,(state.time-state.sourceHandoffAt)/0.34)
else


pose=edit(state.startPose or base,target,state.phaseAge/0.46)
end




if not sourceExactLens and not sourcePhysicalPassive then pose=clampCameraVolume(pose,arena,activePhase) end
if state.sourceHandoff and state.time-state.sourceHandoffAt>=0.34 then state.sourceHandoff=nil;state.sourceHandoffAt=0 end
pose=presentPose(pose,sourceExactLens or sourcePhysicalPassive or state.sourcePresentationClock,state.manual)
if not sourceExactLens and not sourcePhysicalPassive then pose=clampCameraVolume(pose,arena,activePhase) end
state.lastPose=copyPose(pose);return pose,nil
end

if Pacing then
local directedShot=C.shot
function C:shot(ctx,phase,progress,base,arena)
local previous=state.lastPose and copyPose(state.lastPose)
local gen3=V.Gen3Presentation and V.Gen3Presentation.session
local gen3Owned=V.Gen3BattleCamera and gen3 and gen3.screen==ctx.battle








local tempo=V.BattleTempo and V.BattleTempo.active and V.BattleTempo.active(ctx and ctx.game) or nil
local rush=V.BattleTempo and V.BattleTempo.rush and V.BattleTempo.rush(ctx and ctx.game) or 1
local speed=gen3Owned and (tempo or 1)*rush or battleSpeed(ctx);local cfg=Pacing.config(speed)




state.pacingOwnsDisplay=cfg.active and not state.manual
local pose,extra=directedShot(self,ctx,phase,progress,base,arena)
state.pacingOwnsDisplay=nil
if not (Pacing and pose) then return pose,extra end
if ctx and ctx.__cbeBossCameraComfort then
state.comfort=ctx.__cbeBossCameraComfort;ctx.__cbeBossCameraComfort=nil
end
local active=state.phase
local key=tostring(active)..":"..tostring(state.eventIndex)..":"..tostring(state.sourceIdentity or "")


if state.sourcePresentationClock then key="source:"..tostring(state.sourceIdentity or "") end
local critical=active=="capture" or active=="faint" or active=="switch" or active=="exit"
if state.manual then state.comfort=nil;return pose,extra end
local out
if cfg.active and not state.sourcePresentationClock then pose=self:guardPacedPose(pose,arena) end
out,state.comfort=Pacing.apply(state.comfort,pose,{speed=speed,clock=state.time,clockIsPresentation=true,
frameDriven=state.frameDriven,
sourcePresentation=state.sourcePresentationClock,key=key,critical=critical,seed=previous or self:guardPacedPose(base,arena)})
if out then


if state.comfort.adapted and cfg.active then out=Pacing.constrain(state.comfort,self:guardPacedPose(out,arena)) end



state.comfort.output=copyPose(out);state.lastPose=copyPose(out);state.displayPose=copyPose(out)
if gen3Owned then
local owner=state.sourceBattlerId or gen3.cameraTarget
local phase=state.sourcePresentationClock and (state.sourceRole=='damage' and 'damage' or 'attack') or active
local passive=active=='passive' and PASSIVE_SHOTS[state.passiveShotIndex] or nil
local trainerSide=passive and passive.owner=='player-trainer' and 'player'
or (passive and passive.owner=='enemy-trainer' and 'enemy' or nil)
out=V.Gen3BattleCamera.fit(ctx,out,phase,owner,key..':'..tostring(state.passiveShotIndex),
{sourceOwned=state.sourceExactLens==true,sourceChapter=state.sourcePresentationClock==true,
trainerSide=trainerSide})
end
return out,extra
end
return pose,extra
end
end
function C:finish(ctx,reason)
state.comfort=nil;state.comfortMaster=nil
state.lastPose=nil;state.startPose=nil;state.displayPose=nil;state.displayClock=nil;state.mouseX=nil;state.mouseY=nil;state.special=nil
state.presentInput=nil;state.displaySign=nil;state.floorScale=nil;state.floorScaleAt=nil
state.pendingEvent=nil;state.resultPending=nil;state.resultAt=0;state.shotLockUntil=0;state.lastCutTime=-999;state.lastEventName=nil
state.sourcePose=nil;state.sourceIdentity=nil;state.sourcePoseAt=0;state.sourceHandoff=nil;state.sourceHandoffAt=0
state.actionAxisAttacker=nil;state.actionAxisSign=nil
state.passiveShotAge=0;state.passiveTimer=PASSIVE_RANDOM_INTERVAL;state.passiveMotionMode=2;state.passiveLastMotionMode=nil
state.passiveSourcePlan=nil;state.passiveSourceTargetResolved=false
state.passiveFloorFallbackActive=false;state.passiveFloorFallbackMoving=false
state.manual=false;state.manualLocked=false;state.manualIdle=0;state.returning=false
end
function C:status()
local passive=PASSIVE_SHOTS[state.passiveShotIndex]
local source=state.passiveSourcePlan
local passiveDuration=(source and source.durationExact and tonumber(source.durationSeconds))
or (passive and (passive.hold or 0) or 0)
return {manual=state.manual,manualLocked=state.manualLocked,manualIdle=state.manualIdle,radius=state.radius,elevation=state.elevation,fov=state.fov,focus=copy3(state.focus),idleShots=#PASSIVE_SHOTS,commandShots=#COMMAND_SHOTS,idleAxisCuts=true,director="colosseum-semantic-director-v22-hsd-passive-rng",shotOffset=state.shotOffset,eventIndex=state.eventIndex,authoredZoomOut=AUTHORED_ZOOM_OUT,phase=state.phase,eventSide=state.eventSide,shotLockRemaining=math.max(0,state.shotLockUntil-state.time),pendingEvent=state.pendingEvent and state.pendingEvent.phase or nil,lastEvent=state.lastEventName,eventResult=state.eventResult,resultPending=state.resultPending,logicSpeed=state.logicSpeed,clock=Pacing and "speed-compensated-presentation" or "battle-fixed-step-speed-coherent",highSpeedMaster=state.comfort and state.comfort.wide==true or false,cameraComfort=state.comfort and state.comfort.adapted==true or false,cameraComfortEdits=state.comfort and state.comfort.edits or 0,cameraComfortHold=state.comfort and state.comfort.hold or 0,mobileHudSafe=true,safeVolumes=true,subjectReadabilityGuard=true,sourceEyeSpeed=30,sourceFocusSpeed=22,sourceFovSpeed=24,sourceHandoff=state.sourceHandoff~=nil,sourcePresentationClock=state.sourcePresentationClock==true,actionAxisAttacker=state.actionAxisAttacker,actionAxisSign=state.actionAxisSign,passiveShotIndex=state.passiveShotIndex,passiveOwner=passive and passive.owner or nil,passiveShotAge=state.passiveShotAge,passiveMotionMode=state.passiveMotionMode,passiveLastMotionMode=state.passiveLastMotionMode,passiveMotionDuration=passiveDuration,passiveMotionActive=state.phase=="passive" and state.passiveShotAge<passiveDuration,passiveFloorFallbackActive=state.passiveFloorFallbackActive==true,passiveFloorFallbackMoving=state.passiveFloorFallbackMoving==true,passiveFloorFallbackExact=false,passiveFloorFallbackKind="finite-camera-right-truck",passiveFloorFallbackDuration=PASSIVE_FLOOR_SETTLE_DURATION,passiveTimer=state.passiveTimer,passiveRandomInterval=PASSIVE_RANDOM_INTERVAL,passiveRandomGate=PASSIVE_RANDOM_GATE,passiveRngAlgorithm="GC6E01 HSD 0x343FD+0x269EC3 high16/65536",passiveRngAlgorithmExact=true,passiveRngSeedExact=false,passiveFallbackTableExact=PASSIVE_FALLBACK_TABLE_EXACT,commandFallbackTableExact=COMMAND_FALLBACK_TABLE_EXACT,retailFloorCameraAnimationId=RETAIL_FLOOR_CAMERA_ANIMATION_ID,retailFloorCameraAnimationIdExact=true,retailFloorCameraResourceId=RETAIL_FLOOR_CAMERA_ANIMATION_ID,retailFloorCameraResourceIdExact=true,retailFloorCameraResourceKeySource="GC6E01 FSYS nameHash/loadMode",retailFloorCameraAnimationRate=RETAIL_FLOOR_CAMERA_ANIMATION_RATE,retailFloorCameraAnimationRateExact=true,retailFloorCameraFramesPerSecond=30,retailFloorCameraRestoreFrameExact=true,retailFloorCameraLoopExact=true,retailFloorCameraOffsetTransformExact=true,retailFloorCameraOffsetTransformRuntimeApplied=false,retailFloorScaleDolly=state.floorScale or 1,retailFloorCameraOffsetScaleExact=true,retailFloorCameraOffsetPositionExact=true,retailFloorCameraOffsetRotationExact=true,retailFloorCameraWorldUpExact=true,retailFloorCameraRuntimePlaybackActive=false,retailFloorCameraPoseExact=false,retailFloorCameraPoseBlocker="CBE PKX presentation normalization/custom anchors no longer share the retail floor/grid affine",passiveSourceMotionSet="3/0/1/2",passiveSourceAngleFormulaExact=source and source.angleFormulaExact==true or false,passiveSourceAngleRngExact=source and source.angleRngExact==true or false,passiveSourcePhysicalFormulaExact=source and source.physicalFormulaExact==true or false,passiveSourceScaleSelector=source and source.selector or nil,passiveSourceOwnerYaw=source and source.ownerYaw or nil,passiveSourceReverse=source and source.reverse or nil,passiveSourceTargetField=source and source.targetField or nil,passiveSourceTargetFieldExact=source and source.targetFieldExact==true or false,passiveSourceTargetResolved=state.passiveSourceTargetResolved==true,passiveSourceRadiusExact=source and source.radiusAbsoluteExact==true or false,passiveSourceDurationExact=source and source.durationExact==true or false,passiveSourceFovFormulaExact=source and source.fovFormulaExact==true or false,passiveSourceFovRngExact=source and source.fovRngExact==true or false,passiveSourceFovTimingExact=source and source.fovTimingExact==true or false,passiveSourceFovExact=source and source.fovExact==true or false,commandHeld=true,highBroadcast=true,finitePassiveArcs=true}
end
C._test=C._test or {}
C._test.orbitMix=orbitMix
C._test.hsdRandStep=hsdRandStep
C._test.hsdRandBounded=function(seed,range)
return hsdRandBoundedStep(seed,range)
end
C._test.hsdSelectDifferentMotion=hsdSelectDifferentMotion
C._test.hsdSelectDifferentBounded=hsdSelectDifferentBounded
C._test.retailFloorCameraScale=retailFloorCameraScale
C._test.retailFloorCameraMaxSelector=retailFloorCameraMaxSelector
C._test.retailFloorCameraOffsetPose=retailFloorCameraOffsetPose
C._test.liveRetailFloorScale=liveRetailFloorScale
C._test.sizeClassDolly=sizeClassDolly
return C
