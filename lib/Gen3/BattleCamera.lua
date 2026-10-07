



















local V=...
local C={}
local WINDOW={left=-.88,right=.88,top=.67,bottom=-.62}
local function copy(p) return {eye={p.eye[1],p.eye[2],p.eye[3]},focus={p.focus[1],p.focus[2],p.focus[3]},fov=p.fov,curve=p.curve} end
local function clamp(v,a,b) if v<a then return a elseif v>b then return b end return v end
local function finite(v) return type(v)=='number' and v==v and math.abs(v)<math.huge end
local function wallNow()
if love and love.timer and type(love.timer.getTime)=='function' then
local ok,v=pcall(love.timer.getTime);if ok and finite(v) then return v end
end
end
function C.subject(ctx,r,grounded)
local P=V.Gen3Presentation
local x,z,dx,dz=P.anchor(ctx,r.battlerId);if not x then return end
local k=(ctx.services or {}).figureScale or ctx.arena.figureScale or 1
local a=r.actor
local h=math.max(1,(a and a.height or 16)*(a and a.worldScale or 1)*k)
local ground=(ctx.groundY or 0)*k
local center={x*k,ground+h*.5,z*k}


if a and a.matrix and a.attachment then
a:matrix(x,ctx.groundY or 0,z,dx,dz)
local joint=a:attachment('center')



if not grounded and not r.pendingFaint and joint and joint.position and joint.position[2]*k>=ground and not a.forceBasePlayback then
center={joint.position[1]*k,joint.position[2]*k,joint.position[3]*k}
end
if grounded or r.pendingFaint then


center[2]=ground+math.max(0,((a.authoredMinY or 0)*(a.worldScale or 1)+(a.floorLift or 0)+(a.hoverLift or 0))*k)+h*.5
end
end
local bounds=a and a.scene and a.scene.bounds
local radius=h*.45
if bounds then
if r.pendingFaint then
local diagonal=0;for i=1,3 do diagonal=diagonal+(bounds.max[i]-bounds.min[i])^2 end


radius=math.max(radius,math.sqrt(diagonal)*(a.worldScale or 1)*k*.6)
else
radius=math.max(radius,math.max(bounds.max[1]-bounds.min[1],bounds.max[3]-bounds.min[3])*(a.worldScale or 1)*k*.5)
end
end
return {id=r.battlerId,center=center,height=h,radius=math.max(.75,radius),ground=ground}
end
function C.trainerSubject(ctx,side)
local actor=side=='player' and V.PlayerTrainer or V.Trainer
if not (actor and type(actor.anchor)=='function') then return nil end
local height=6.9
if type(actor.status)=='function' then
local ok,status=pcall(actor.status,actor)
local measured=ok and type(status)=='table' and tonumber(status.battleHeight)
if finite(measured) and measured>2 and measured<16 then height=measured end
end
local ok,p=pcall(actor.anchor,actor,height*.5)
if not ok or type(p)~='table' then return nil end
local x,y,z=tonumber(p[1]),tonumber(p[2]),tonumber(p[3])
if not (finite(x) and finite(y) and finite(z)) then return nil end

return {id='trainer:'..side,center={x,y,z},height=height,radius=height*.53,ground=0}
end
function C.project(p,v,aspect)
local dx,dy,dz=p.focus[1]-p.eye[1],p.focus[2]-p.eye[2],p.focus[3]-p.eye[3]
local n=math.sqrt(dx*dx+dy*dy+dz*dz);if n<1e-6 then return end
dx,dy,dz=dx/n,dy/n,dz/n
local r=math.sqrt(dx*dx+dz*dz);if r<1e-6 then return end
local rx,rz=-dz/r,dx/r
local x,y,z=v[1]-p.eye[1],v[2]-p.eye[2],v[3]-p.eye[3]
local depth=x*dx+y*dy+z*dz;if depth<=.15 then return end
local t=math.tan(p.fov*.5)
return (x*rx+z*rz)/(depth*t*aspect),(-x*rz*dy+y*r+z*rx*dy)/(depth*t),depth
end
function C.readable(p,subjects,aspect)
for _,s in ipairs(subjects) do
local x,y,d=C.project(p,s.center,aspect)
if not x then return false end
local half=s.radius/(d*math.tan(p.fov*.5))




local epsilon=1e-7
if math.abs(x)+half/aspect>WINDOW.right+epsilon or y+half>WINDOW.top+epsilon
or y-half<WINDOW.bottom-epsilon then return false end
end
return #subjects>0
end
local function basis(p)
local dx,dy,dz=p.focus[1]-p.eye[1],p.focus[2]-p.eye[2],p.focus[3]-p.eye[3]
local n=math.sqrt(dx*dx+dy*dy+dz*dz);if n<1e-6 then return end
dx,dy,dz=dx/n,dy/n,dz/n
local r=math.sqrt(dx*dx+dz*dz);if r<1e-6 then return end
local rx,rz=-dz/r,dx/r
return {forward={dx,dy,dz},right={rx,0,rz},up={-rz*dy,r,rx*dy},dist=n}
end

local function extents(p,subjects,aspect)
local t=math.tan(p.fov*.5)
local x0,x1,y0,y1,depth=math.huge,-math.huge,math.huge,-math.huge,0
for _,s in ipairs(subjects) do
local x,y,d=C.project(p,s.center,aspect)
if not x then return nil end
local half=s.radius/(d*t)
x0=math.min(x0,x-half/aspect);x1=math.max(x1,x+half/aspect)
y0=math.min(y0,y-half);y1=math.max(y1,y+half)
depth=depth+d
end
return x0,x1,y0,y1,depth/#subjects
end
local function dolly(p,k)
local out=copy(p)
for i=1,3 do out.eye[i]=p.focus[i]+(p.eye[i]-p.focus[i])*k end
return out
end
local function fits(p,subjects,aspect)
local x0,x1,y0,y1=extents(p,subjects,aspect)
return x0 and (x1-x0)<=(WINDOW.right-WINDOW.left) and (y1-y0)<=(WINDOW.top-WINDOW.bottom)
end

local function solveDolly(p,subjects,aspect,minimum)
minimum=math.max(1,minimum or 1)
if fits(dolly(p,minimum),subjects,aspect) then return minimum end
local lo,hi=minimum,minimum*1.25
while not fits(dolly(p,hi),subjects,aspect) do
lo=hi;hi=hi*1.25
if hi>8 then return 8 end
end
for _=1,22 do
local mid=(lo+hi)*.5
if fits(dolly(p,mid),subjects,aspect) then hi=mid else lo=mid end
end
return hi
end

local function solveTruck(p,subjects,aspect)
local q=copy(p);local T={0,0,0}
for _=1,4 do
local x0,x1,y0,y1,depth=extents(q,subjects,aspect)
if not x0 then break end
local sx,sy=0,0
if x1-x0>(WINDOW.right-WINDOW.left) then sx=-(x0+x1)*.5
elseif x0<WINDOW.left then sx=WINDOW.left-x0 elseif x1>WINDOW.right then sx=WINDOW.right-x1 end
if y1-y0>(WINDOW.top-WINDOW.bottom) then sy=(WINDOW.top+WINDOW.bottom)*.5-(y0+y1)*.5
elseif y0<WINDOW.bottom then sy=WINDOW.bottom-y0 elseif y1>WINDOW.top then sy=WINDOW.top-y1 end
if math.abs(sx)<1e-4 and math.abs(sy)<1e-4 then break end
local b=basis(q);if not b then break end
local t=math.tan(q.fov*.5)

local mx,my=-sx*depth*t*aspect,-sy*depth*t
for i=1,3 do
local v=b.right[i]*mx+b.up[i]*my
q.eye[i]=q.eye[i]+v;q.focus[i]=q.focus[i]+v;T[i]=T[i]+v
end
end
return T
end
local function apply(p,k,T)
local out=dolly(p,k)
for i=1,3 do out.eye[i]=out.eye[i]+T[i];out.focus[i]=out.focus[i]+T[i] end
return out
end

local function isCut(a,b)
if not a then return true end
local ba,bb=basis(a),basis(b);if not (ba and bb) then return true end
local d=0;for i=1,3 do d=d+(a.eye[i]-b.eye[i])^2 end;d=math.sqrt(d)
local cos=ba.forward[1]*bb.forward[1]+ba.forward[2]*bb.forward[2]+ba.forward[3]*bb.forward[3]
return d>math.max(4,ba.dist*.22) or cos<math.cos(math.rad(25)) or math.abs(a.fov-b.fov)>math.rad(8)
end


local function stable(state,subject,dt,snap)
state.subjects=state.subjects or {}
local f=state.subjects[subject.id]
local c=subject.center
if snap or not f then
f={center={c[1],c[2],c[3]}};state.subjects[subject.id]=f
else
local jump=0;for i=1,3 do jump=math.max(jump,math.abs(c[i]-f.center[i])) end
if jump>subject.height*1.5 then
f.center={c[1],c[2],c[3]}
else
local a=1-math.exp(-dt*5)
for i=1,3 do f.center[i]=f.center[i]+(c[i]-f.center[i])*a end
end
end
return {id=subject.id,center={f.center[1],f.center[2],f.center[3]},height=subject.height,radius=subject.radius,ground=subject.ground}
end
local function distance(a,b)
return math.sqrt((a[1]-b[1])^2+(a[2]-b[2])^2+(a[3]-b[3])^2)
end






local function sourceObstruction(ctx,pose,targetId,aspect)
local P=V.Gen3Presentation
local r=P and P.records and P.records[targetId]
if not (r and r.visible and r.actor) then return nil end
local target=C.subject(ctx,r)
if not target then return nil end
local tx,ty,td=C.project(pose,target.center,aspect)
for id=0,3 do
local other=P.records[id]
if id~=targetId and other and other.visible and not other.structuralHidden and other.actor then
local blocker=C.subject(ctx,other)
if blocker then
local near=distance(pose.eye,blocker.center)<blocker.radius*1.55
local bx,by,bd=C.project(pose,blocker.center,aspect)
local projected=bx and tx and bd<td and bd>.15
local br=projected and blocker.radius/(bd*math.tan(pose.fov*.5)) or 0
local overlap=projected and math.sqrt(((bx-tx)*aspect)^2+(by-ty)^2)<br*.82
if near or (overlap and br>.28) then return blocker,target,near and 'eye-inside-actor' or 'partner-occludes-target' end
end
end
end
if distance(pose.eye,target.center)<target.radius*1.25 then return target,target,'eye-inside-target' end
end
local function sourceEscape(pose,blocker,target)
local c,b=target.center,blocker.center
local dx,dz=c[1]-b[1],c[3]-b[3]
local n=math.sqrt(dx*dx+dz*dz)
if n<.01 then dx,dz=c[1]-pose.eye[1],c[3]-pose.eye[3];n=math.sqrt(dx*dx+dz*dz) end
if n<.01 then dx,dz,n=0,1,1 end
dx,dz=dx/n,dz/n
local rx,rz=-dz,dx
local sign=(pose.eye[1]-c[1])*rx+(pose.eye[3]-c[3])*rz>=0 and 1 or -1
local range=math.max(21,target.height*3.1,blocker.radius*4.2)
local focus={c[1],c[2],c[3]}
return {eye={c[1]+dx*range*.68+rx*range*.70*sign,
c[2]+range*.30,c[3]+dz*range*.68+rz*range*.70*sign},
focus=focus,fov=math.max(pose.fov,math.rad(41)),curve=0}
end
function C.fit(ctx,pose,phase,targetId,key,options)
local P=V.Gen3Presentation;local session=P and P.session
if not (session and session.screen==ctx.battle) then return pose end
local state=session.cameraFit
if not state then state={k=1,T={0,0,0}};session.cameraFit=state end
options=options or {}
local faint=P.faintActive();if faint then targetId=faint.battlerId;phase='faint' end
local targetRecord=P.records[targetId]
local removedOwner=not faint and targetRecord and targetRecord.faintedVisual==true
local removalCut=removedOwner and state.removedOwnerRecord~=targetRecord
state.removedOwnerRecord=removedOwner and targetRecord or nil
if removedOwner then
local safe={};for k,v in pairs(options)do safe[k]=v end
safe.sourceOwned=false;safe.sourceChapter=false;options=safe
state.sourceRescue=nil
end
local occlusionGuard=phase=='attack' or phase=='damage' or phase=='reaction'
if (options.sourceOwned or options.sourceChapter or occlusionGuard) and not faint then
local rescue=state.sourceRescue
if rescue and rescue.key~=key then rescue=nil;state.sourceRescue=nil end
if not rescue then
local size=(ctx.services or {}).renderSize or {}
local aspect=(size.width or 1280)/math.max(1,size.height or 720)
local blocker,target,why=sourceObstruction(ctx,pose,targetId,aspect)
if blocker then
rescue={key=key,pose=sourceEscape(pose,blocker,target),reason=why,target=targetId}
state.sourceRescue=rescue
end
end
if rescue or options.sourceOwned then




state.k=1;state.T={0,0,0};state.subjects=nil;state.input=copy(pose)
state.faint=nil;state.wasFaint=nil;state.clock=wallNow()
C.last={phase=phase,ids={},adjusted=rescue~=nil,mode=rescue and 'source-occlusion-escape' or 'source-owned',
reason=rescue and rescue.reason,target=targetId}
return rescue and copy(rescue.pose) or pose
end
end
if not (options.sourceChapter or occlusionGuard) then state.sourceRescue=nil end
local now=wallNow()
local dt=(now and state.clock) and clamp(now-state.clock,0,.1) or (1/60)
state.clock=now
local cut=isCut(state.input,pose) or removalCut
state.input=copy(pose)
local exempt=phase=='capture' or phase=='intro' or phase=='switch' or phase=='free'
if state.wasFaint and phase~='faint' then cut=true end
local size=(ctx.services or {}).renderSize or {}
local aspect=(size.width or 1280)/math.max(1,size.height or 720)
local raw={}
if not exempt then
if phase=='passive' and options.trainerSide then
local trainer=C.trainerSubject(ctx,options.trainerSide)
if trainer then raw[1]=trainer end
end
if phase=='faint' or phase=='attack' or phase=='damage' then
local r=P.records[targetId]
if r and (r.visible or r.pendingFaint) and not r.faintedVisual then raw[1]=C.subject(ctx,r) end
end
if #raw==0 then
for id=0,3 do local r=P.records[id]
if r and r.visible and not r.faintedVisual and not r.structuralHidden then raw[#raw+1]=C.subject(ctx,r,phase=='command') end
end
end
if phase=='command' then
for _,side in ipairs({'player','enemy'}) do
local provider=side=='player' and V.PlayerTrainer or V.Trainer
if provider and provider.shouldRender and provider:shouldRender(ctx) then
local trainer=C.trainerSubject(ctx,side);if trainer then raw[#raw+1]=trainer end
end
end
end
end



local occupantIds={};for _,subject in ipairs(raw)do occupantIds[#occupantIds+1]=subject.id end
local occupantKey=table.concat(occupantIds,':')
if state.occupantKey and state.occupantKey~=occupantKey then cut=true;state.subjects=nil end
state.occupantKey=occupantKey
if phase=='faint' and raw[1] then



local subject=raw[1]
local f=state.faint
if not (f and f.id==subject.id) then
local x,z=pose.eye[1]-subject.center[1],pose.eye[3]-subject.center[3]
local n=math.max(.01,math.sqrt(x*x+z*z))
local distance=math.max(8,subject.height*3.4,subject.radius*6)
f={id=subject.id,center={subject.center[1],subject.center[2],subject.center[3]},
offset={x/n*distance,distance*.22,z/n*distance},scale=1}
state.faint=f
end
local out=copy(pose)
for i=1,3 do out.focus[i]=f.center[i];out.eye[i]=f.center[i]+f.offset[i] end
if not C.readable(dolly(out,f.scale),raw,aspect) then
local lo,hi=f.scale,f.scale*1.06
while not C.readable(dolly(out,hi),raw,aspect) and hi<f.scale*6 do lo=hi;hi=hi*1.06 end
for _=1,18 do local mid=(lo+hi)*.5;if C.readable(dolly(out,mid),raw,aspect) then hi=mid else lo=mid end end
f.scale=hi
end
out=dolly(out,f.scale)
state.wasFaint=true;state.subjects=nil

state.k=1;state.T={0,0,0}
C.last={phase=phase,ids={subject.id},adjusted=true,readable=C.readable(out,raw,aspect),k=f.scale,mode='faint'}
return out
end
state.faint=nil;state.wasFaint=nil
local subjects={};local ids={}
for i,s in ipairs(raw) do subjects[i]=stable(state,s,dt,cut);ids[i]=s.id end

local kT,TT=1,{0,0,0}
if #subjects>0 and not C.readable(pose,subjects,aspect) then
kT=solveDolly(pose,subjects,aspect)
TT=solveTruck(dolly(pose,kT),subjects,aspect)
end
if cut then
state.k=kT;state.T={TT[1],TT[2],TT[3]}
else

local ak=1-math.exp(-dt*(kT>state.k and 9 or 2.2))
state.k=state.k+(kT-state.k)*ak
local at=1-math.exp(-dt*5)
for i=1,3 do state.T[i]=state.T[i]+(TT[i]-state.T[i])*at end
end
local adjusted=math.abs(state.k-1)>1e-4 or math.abs(state.T[1])+math.abs(state.T[2])+math.abs(state.T[3])>1e-4
local out=adjusted and apply(pose,state.k,state.T) or pose
C.last={phase=phase,ids=ids,adjusted=adjusted,readable=#subjects>0 and C.readable(out,subjects,aspect) or nil,
k=state.k,truck={state.T[1],state.T[2],state.T[3]},cut=cut,mode='continuous'}
return out
end
C._test={solveDolly=solveDolly,solveTruck=solveTruck,extents=extents,isCut=isCut,window=WINDOW}
return C
