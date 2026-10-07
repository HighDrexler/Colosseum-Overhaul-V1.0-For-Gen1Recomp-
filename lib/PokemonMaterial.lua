
local UNIT2={1,1}
local SOURCE_TEX_ID0={1,0,0,0}
local SOURCE_TEX_ID1={1,0}
local sourceTexRow0={1,0,0,0}
local sourceTexRow1={1,0}
local function sourceFobjValue(keys,frame)
if not keys or #keys==0 then return nil end
if frame<(tonumber(keys[1].frame) or 0) then return nil end
if frame>=(tonumber(keys[#keys].frame) or 0) then
for i=#keys,1,-1 do if tonumber(keys[i].op)~=5 then return tonumber(keys[i].value) end end
return nil
end
local p0,p1,d0,d1,t0,t1=0,0,0,0,0,0;local opPrev,op=1,1
for _,k in ipairs(keys) do
opPrev=op;op=tonumber(k.op) or 0
local value,tan,kframe=tonumber(k.value) or 0,tonumber(k.tan) or 0,tonumber(k.frame) or 0
if op==1 or op==2 then p0=p1;p1=value;if opPrev~=5 then d0=d1;d1=0 end;t0=t1;t1=kframe
elseif op==3 then p0=p1;d0=d1;p1=value;d1=0;t0=t1;t1=kframe
elseif op==4 then p0=p1;p1=value;d0=d1;d1=tan;t0=t1;t1=kframe
elseif op==5 then d0=d1;d1=tan
elseif op==6 then p0=p1;p1=value;t0=t1;t1=kframe end
if t1>frame and op~=5 then break end
opPrev=op
end
if frame<=t0 then return p0 end;if frame>=t1 then return p1 end
if t0==t1 or opPrev==1 or opPrev==6 then return p0 end
local time=frame-t0;local span=t1-t0
if opPrev==2 then return p0+(p1-p0)*(time/span) end
if opPrev==3 or opPrev==4 or opPrev==5 then
local inv=1/span;local f1=time*time;local f2=inv*inv*f1*time;local f3=3*f1*inv*inv;local f4=f2-f1*inv;local f2b=2*f2*inv
return d1*f4+d0*(time+(f4-f1*inv))+p0*(1+(f2b-f3))+p1*(-f2b+f3)
end
return p0
end



local function facialSequence(anim)
if anim._facialSequence~=nil then return anim._facialSequence end
local ending=tonumber(anim.endFrame) or 0;local changed=false
local short=ending>0 and ending<=12
for track,keys in pairs(anim.tracks or {}) do
local first=keys[1] and keys[1].value
for _,key in ipairs(keys) do
if key.value~=first then
changed=true
if (track~=2 and track~=3) or (key.op~=1 and key.op~=6) then short=false end
end
end
end
anim._facialSequence=short and changed
return anim._facialSequence
end
local function animationFrame(anim,time)
local ending=tonumber(anim.endFrame) or 0
local frame=(tonumber(time) or 0)*(tonumber(anim.framesPerSecond) or 30)
if facialSequence(anim) and anim.loop~=false then
local cycle=frame%(96+(ending+1)*2)
if cycle<96 then return 0 end

local step=math.floor(cycle-96)
return math.min(ending,math.max(0,step<=ending and step or ending*2+1-step))
end
if anim.loop~=false and ending>0 then return frame%ending end
return ending>0 and math.min(frame,ending) or frame
end
local function sourceTextureAnimationRows(g,time)
local anim=g and g.sourceTextureAnimation
if type(anim)~="table" then return 0,SOURCE_TEX_ID0,SOURCE_TEX_ID1 end
if anim.state~="animated" then return 1,SOURCE_TEX_ID0,SOURCE_TEX_ID1 end
local base=anim.base
if type(base)~="table" or type(base.baseInverse)~="table" then return 1,SOURCE_TEX_ID0,SOURCE_TEX_ID1 end
local scale=base.scale or UNIT2;local translation=base.translation or {0,0}
local sx0,sy0=tonumber(scale[1]) or 1,tonumber(scale[2]) or 1
local tx,ty=tonumber(translation[1]) or 0,tonumber(translation[2]) or 0
local rz=tonumber(base.rotationZ) or 0
local endFrame=tonumber(anim.endFrame) or 0
local frame=animationFrame(anim,time)
local tracks=anim.tracks or {}
local v=sourceFobjValue(tracks[2],frame);if v~=nil then tx=v end
v=sourceFobjValue(tracks[3],frame);if v~=nil then ty=v end
v=sourceFobjValue(tracks[4],frame);if v~=nil then sx0=v end
v=sourceFobjValue(tracks[5],frame);if v~=nil then sy0=v end
v=sourceFobjValue(tracks[8],frame);if v~=nil then rz=v end
local rs,rt=tonumber(base.repeatS) or 1,tonumber(base.repeatT) or 1
if rs<=0 or rt<=0 then return 1,SOURCE_TEX_ID0,SOURCE_TEX_ID1 end
local us=math.abs(sx0)<1e-10 and 0 or rs/sx0
local vs=math.abs(sy0)<1e-10 and 0 or rt/sy0
local mirror=(tonumber(base.wrapT) or 0)==2 and sy0/rt or 0
local c,s=math.cos(rz),math.sin(rz)
local px,py=-tx,-(ty+mirror)

local a,b=us*c,us*s;local d,e=-vs*s,vs*c
local cc=us*(c*px+s*py);local ff=vs*(-s*px+c*py)
local inv=base.baseInverse
local ia,ib,ic,id,ie,ifv=tonumber(inv[1]),tonumber(inv[2]),tonumber(inv[3]),tonumber(inv[4]),tonumber(inv[5]),tonumber(inv[6])
if not (ia and ib and ic and id and ie and ifv) then return 1,SOURCE_TEX_ID0,SOURCE_TEX_ID1 end
sourceTexRow0[1]=a*ia+b*id;sourceTexRow0[2]=a*ib+b*ie;sourceTexRow0[3]=a*ic+b*ifv+cc
sourceTexRow0[4]=d*ia+e*id;sourceTexRow1[1]=d*ib+e*ie;sourceTexRow1[2]=d*ic+e*ifv+ff
return 1,sourceTexRow0,sourceTexRow1
end




local function bakeTexture(t)
if not t or not t.tev or t.tevBaked or type(t.rgba)~='string' then return false end
local q=t.tev.bytes;local flags=t.tev.active or 0
local rgb=math.floor(flags/0x40000000)%2==1
local alpha=math.floor(flags/0x80000000)%2==1
if not rgb and not alpha then return false end
local function input(code,channel,pixel,isAlpha)
if isAlpha then
if code==7 then return 0 elseif code==4 then return pixel[4]
elseif code>=64 and code<=67 then return q[17+code-64]/255
elseif code==68 then return q[24]/255 elseif code==69 then return q[28]/255 end
else
if code==15 then return 0 elseif code==12 then return 1 elseif code==13 then return .5
elseif code==8 then return pixel[channel] elseif code==9 then return pixel[4]
elseif code==128 then return q[16+channel]/255
elseif code>=129 and code<=132 then return q[17+code-129]/255
elseif code==133 then return q[20+channel]/255 elseif code==134 then return q[24]/255
elseif code==135 then return q[24+channel]/255 elseif code==136 then return q[28]/255 end
end
end
local function channel(pixel,k,isAlpha)
local off=isAlpha and 12 or 8;local oi=isAlpha and 2 or 1
local a,b,c,d=input(q[off+1],k,pixel,isAlpha),input(q[off+2],k,pixel,isAlpha),input(q[off+3],k,pixel,isAlpha),input(q[off+4],k,pixel,isAlpha)
if not (a and b and c and d) or q[oi]>1 or q[oi+2]>2 or q[oi+4]>3 then return nil end
local mix=a*(1-c)+b*c
local v=d+(q[oi]==1 and -mix or mix)
v=v+(q[oi+2]==1 and .5 or q[oi+2]==2 and -.5 or 0)
v=v*({1,2,4,.5})[q[oi+4]+1]


if q[oi+6]==0 and (v<0 or v>1) then return nil end
return math.max(0,math.min(1,v))
end
local pixels={}
for i=1,#t.rgba,4 do
local r,g,b,a=t.rgba:byte(i,i+3);local p={r/255,g/255,b/255,a/255}
if t.format==0 or t.format==1 then p[4]=p[1] end
local out={p[1],p[2],p[3],p[4]}
if rgb then for k=1,3 do out[k]=channel(p,k,false);if out[k]==nil then return false,'unsupported static color TEV' end end end
if alpha then out[4]=channel(p,4,true);if out[4]==nil then return false,'unsupported static alpha TEV' end end
pixels[#pixels+1]=string.char(math.floor(out[1]*255+.5),math.floor(out[2]*255+.5),math.floor(out[3]*255+.5),math.floor(out[4]*255+.5))
end
t.rgba=table.concat(pixels);t.sourceFormat=t.format;t.format=6;t.tevBaked=true
return true
end

return {rows=sourceTextureAnimationRows,value=sourceFobjValue,bakeTexture=bakeTexture,frame=animationFrame,facialSequence=facialSequence}
