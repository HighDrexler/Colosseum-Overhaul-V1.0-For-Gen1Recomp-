













local P={version=3}
local function finite(x)return type(x)=="number" and x==x and math.abs(x)<math.huge end
local function clamp(x,a,b)return math.max(a,math.min(b,x))end
local function atan(y,x)return math.atan2 and math.atan2(y,x) or math.atan(y,x)end
local function copy(p)return {eye={p.eye[1],p.eye[2],p.eye[3]},focus={p.focus[1],p.focus[2],p.focus[3]},fov=p.fov,curve=0}end
local function valid(p)
if type(p)~="table" or type(p.eye)~="table" or type(p.focus)~="table" or not finite(p.fov) or p.fov<=0 or p.fov>=math.pi then return false end
local r=0
for i=1,3 do if not finite(p.eye[i]) or not finite(p.focus[i]) then return false end;r=r+(p.eye[i]-p.focus[i])^2 end
return r>1e-10
end
local function safeSpeed(v)
v=tonumber(v);return finite(v) and clamp(v,1,64) or 1
end
function P.speed(ctx,session,mod)
local battle=type(ctx)=="table" and ctx.battle
local game=(type(ctx)=="table" and ctx.game) or (battle and battle.game)
or (session and session.screen and session.screen.game)
or (session and session.host and session.host.game) or (mod and mod.game)
game=(game and game.__cbeMtBattleHostGame) or game
if game and type(game.logicSpeed)=="function" then
local ok,value=pcall(game.logicSpeed,game)
if ok and finite(tonumber(value)) then return safeSpeed(value) end
end
local opts=game and game.save and game.save.options or {}
return safeSpeed(opts.speedBattle or opts.speed)
end
function P.config(speed)
speed=safeSpeed(speed)
local tier=speed>=8 and 2 or (speed>=4 and 1 or 0)
return {active=speed>1.05,wide=false,hold=.90+tier*.15,

editMin=.50+tier*.05,editMax=1.10+tier*.10,

rate=4.0-tier*.5,



yaw=math.rad(230-tier*10),pitch=math.rad(135-tier*5),
fov=math.rad(110-tier*5),focus=80-tier*5,range=2.5-tier*.1}
end
local function wrap(d)return (d+math.pi)%(2*math.pi)-math.pi end
local function polar(p)
local x,y,z=p.eye[1]-p.focus[1],p.eye[2]-p.focus[2],p.eye[3]-p.focus[3]
local h=math.sqrt(x*x+z*z)
return atan(x,z),atan(y,math.max(1e-8,h)),math.sqrt(h*h+y*y)
end


local function yawDelta(ay,by,sign)
local d=wrap(by-ay)
if sign and sign~=0 and math.abs(d)>math.pi*.75 and (d>0)~=(sign>0) then d=d+(sign>0 and 2 or -2)*math.pi end
return d
end
local function compose(f,yaw,pitch,r,fov)
local h=math.cos(pitch)*r
return {eye={f[1]+math.sin(yaw)*h,f[2]+math.sin(pitch)*r,f[3]+math.cos(yaw)*h},focus=f,fov=fov,curve=0}
end
local function orbit(a,b,t,sign)
local ay,ap,ar=polar(a);local by,bp,br=polar(b)
local yaw=ay+yawDelta(ay,by,sign)*t
local pitch=ap+(bp-ap)*t;local r=ar+(br-ar)*t
local f={};for i=1,3 do f[i]=a.focus[i]+(b.focus[i]-a.focus[i])*t end
return compose(f,yaw,pitch,r,a.fov+(b.fov-a.fov)*t)
end
local function smooth(t)t=clamp(t,0,1);return t*t*(3-2*t)end

local function editSize(a,b)
local ay,ap,ar=polar(a);local by,bp,br=polar(b)
local fd=0;for i=1,3 do fd=fd+(a.focus[i]-b.focus[i])^2 end;fd=math.sqrt(fd)
local e=math.max(math.abs(wrap(by-ay))/math.pi,math.abs(bp-ap)/(math.pi*.5),
fd/(2*math.max(1,ar)),math.abs(math.log(math.max(1e-6,br)/math.max(1e-6,ar)))/math.log(2),
math.abs(b.fov-a.fov)/math.rad(20))
return clamp(e,0,1)
end



local function largeEdit(a,b)
local ay,ap,ar=polar(a);local by,bp,br=polar(b)
local fd=0;for i=1,3 do fd=fd+(a.focus[i]-b.focus[i])^2 end
return math.abs(wrap(by-ay))>math.rad(70) or math.abs(bp-ap)>math.rad(28) or math.sqrt(fd)>math.max(10,ar*.55)
end
local function beginEdit(s,c,target)
local from=copy(s.output)
if largeEdit(from,target) then
s.trans=nil;s.yawSign=nil;s.output=copy(target);s.cuts=(s.cuts or 0)+1;s.cutAt=s.age
return
end
local ay=polar(from);local by=polar(target)
local d=wrap(by-ay)
s.trans={from=from,age=0,dur=c.editMin+(c.editMax-c.editMin)*editSize(from,target),sign=(d>=0) and 1 or -1}
s.yawSign=s.trans.sign
end


local function limited(a,b,dt,c,hardLimit,sign)
local ay,ap,ar=polar(a);local by,bp,br=polar(b)
local alpha=hardLimit and 1 or (1-math.exp(-dt*c.rate))
local yaw=ay+clamp(yawDelta(ay,by,sign)*alpha,-c.yaw*dt,c.yaw*dt)
local pitch=ap+clamp((bp-ap)*alpha,-c.pitch*dt,c.pitch*dt)
local radius=ar+clamp((br-ar)*alpha,-math.max(1,ar)*c.range*dt,math.max(1,ar)*c.range*dt)
local dx,dy,dz=b.focus[1]-a.focus[1],b.focus[2]-a.focus[2],b.focus[3]-a.focus[3]
local d=math.sqrt(dx*dx+dy*dy+dz*dz)

local limit=c.focus*clamp(ar/60,.35,3)*dt
local t=d>1e-8 and math.min(alpha,limit/d) or 0
local f={a.focus[1]+dx*t,a.focus[2]+dy*t,a.focus[3]+dz*t}
return compose(f,yaw,pitch,radius,a.fov+clamp((b.fov-a.fov)*alpha,-c.fov*dt,c.fov*dt))
end
local function renderDelta(s,opts)
local now
if love and love.timer and type(love.timer.getTime)=="function" then
local ok,v=pcall(love.timer.getTime);if ok and finite(v) then now=v end
end
local clock=tonumber(opts.clock)
local dt=0
if opts.frameDriven and finite(clock) then
if finite(s.logicClock) then dt=clamp(clock-s.logicClock,0,.05) end
s.logicClock=clock;s.renderClock=now
return dt
end
if now then
if s.renderClock then dt=clamp(now-s.renderClock,0,.1) end
s.renderClock=now
else
if finite(clock) and finite(s.logicClock) then
dt=clamp((clock-s.logicClock)/(opts.clockIsPresentation and 1 or safeSpeed(opts.speed)),0,.1)
end

s.renderClock=nil
end
if finite(clock) then s.logicClock=clock end
return dt
end

local function advance(s,c,dt)
local prev=(s.cutAt~=s.age and s.output) and copy(s.output) or nil
local tr=s.trans
if tr then
tr.age=tr.age+dt



tr.dur=math.max(tr.dur,c.editMin+(c.editMax-c.editMin)*editSize(tr.from,s.target))
tr.u=math.min(1,(tr.u or 0)+dt/math.max(1e-3,tr.dur))
local u=tr.u
if u>=1 then
s.trans=nil;s.output=copy(s.target)
else
s.output=orbit(tr.from,s.target,smooth(u),tr.sign)
end
elseif dt>0 then
local a=1-math.exp(-dt*c.rate)
s.output=orbit(s.output,s.target,a,s.yawSign)
end

if prev and dt>0 then s.output=limited(prev,s.output,dt,c,true,(s.trans and s.trans.sign) or s.yawSign) end
end
local function settled(a,b)
local d=0;for i=1,3 do d=math.max(d,math.abs(a.eye[i]-b.eye[i]),math.abs(a.focus[i]-b.focus[i])) end
return d<1e-3 and math.abs(a.fov-b.fov)<1e-4
end
function P.apply(s,target,opts)
opts=opts or {};s=s or {}
if not valid(target) then return s.output and copy(s.output) or (valid(opts.seed) and copy(opts.seed) or nil),s end
local c=P.config(opts.speed);local dt=renderDelta(s,opts)
s.frameOrigin=s.output and copy(s.output) or nil;s.frameDt=dt
s.age=(s.age or 0)+dt
s.speed=safeSpeed(opts.speed);s.wide=c.wide



if opts.sourcePresentation then




local same=s.sourcePresentation and s.output and s.key==opts.key
local track=c.active or (same and (s.sourceAdapted or s.sourceReturning))
if track and same and dt>0 then
local sourceConfig=P.config(opts.speed)
sourceConfig.rate=12
s.output=limited(s.output,target,dt,sourceConfig,false,s.yawSign)
s.sourceReturning=not c.active and not settled(s.output,target) or nil
if not c.active and not s.sourceReturning then s.output=copy(target) end
elseif not track or not same then
s.output=copy(target);s.yawSign=nil
s.sourceReturning=nil
end
s.sourceAdapted=c.active
s.target=nil;s.key=opts.key;s.adapted=false;s.hold=0;s.trans=nil
s.active=false;s.returning=nil;s.sourcePresentation=true
return copy(s.output),s
end
s.sourcePresentation=nil;s.sourceAdapted=nil;s.sourceReturning=nil
if not c.active then
if s.active then


s.returning=true;s.target=copy(target)
if s.output and not s.trans then beginEdit(s,c,target) end
end
s.active=false
if not s.returning or not s.output then
s.output=copy(target);s.target=nil;s.key=nil;s.adapted=false;s.hold=0;s.trans=nil;s.returning=nil
return copy(s.output),s
end
s.target=copy(target)
advance(s,c,dt)
if not s.trans or settled(s.output,target) then
s.returning=nil;s.target=nil;s.key=nil;s.output=copy(target);s.adapted=false;s.hold=0;s.trans=nil
return copy(s.output),s
end
s.adapted=true
return copy(s.output),s
elseif not s.active then
s.active=true;s.returning=nil
s.output=copy(s.output or (valid(opts.seed) and opts.seed) or target)
s.frameOrigin=s.frameOrigin or copy(s.output)
s.target=copy(target);s.key=opts.key;s.committedAt=s.age
s.edits=(s.edits or 0)+1
if not settled(s.output,target) then beginEdit(s,c,target) else s.trans=nil end
end
s.adapted=true


if opts.key==s.key then


local jumped=s.target and largeEdit(s.target,target)
s.target=copy(target);s.suppressedKey=nil
if jumped then beginEdit(s,c,target) end
elseif s.age-(s.committedAt or s.age)>=c.hold*(opts.critical and .65 or 1) then
s.target=copy(target);s.key=opts.key;s.committedAt=s.age;s.edits=(s.edits or 0)+1;s.suppressedKey=nil
beginEdit(s,c,target)
elseif opts.key~=s.suppressedKey then
s.suppressedKey=opts.key;s.coalesced=(s.coalesced or 0)+1
end
advance(s,c,dt)
s.hold=c.hold
return copy(s.output),s
end




function P.constrain(s,projected)
if not (s and s.output and valid(projected)) then return s and s.output and copy(s.output) or projected end
if not s.adapted then return projected end
if settled(s.output,projected) then s.output=copy(projected);return projected end
local out=limited(s.frameOrigin or s.output,projected,s.frameDt or 0,P.config(s.speed),true,s.trans and s.trans.sign or s.yawSign)
s.output=copy(out)
return out
end
P._test={polar=polar,valid=valid,limited=limited,orbit=orbit,yawDelta=yawDelta,editSize=editSize,wrap=wrap,largeEdit=largeEdit}
return P
