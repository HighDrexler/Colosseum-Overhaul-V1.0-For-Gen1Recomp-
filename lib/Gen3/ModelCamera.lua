
local V=...
local req=V.engineRequire or require
local C={}
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
function C.visible(v)
if not v or not v.actor or not v.viewport then return false end
local top=req('src.ui.game3.stack').top()
local owner=v.owner or V.Gen3UI.menu
return top and top.mod==owner and V.Gen3UI.clock-(v.paintedAt or -100)<.25
end
function C.point(v,x,y)
local r=v.viewport;return r and x>=r.x and x<=r.x+r.w and y>=r.y and y<=r.y+r.h
end
function C.state(v)
if not v.camera then v.camera={yaw=0,pitch=.15,zoom=1,panX=0,panY=0} end
return v.camera
end
function C.bind(v,x,y,w,h,hd)
local r=V.Gen3Overlay.rect
if hd and r then v.viewport={x=r.vux+x/r.dpiX,y=r.vuy+y/r.dpiY,w=w/r.dpiX,h=h/r.dpiY}
else v.viewport=nil end
v.paintedAt=V.Gen3UI.clock
end
function C.wheel(_,dy)
local v=V.Gen3UI.viewer
if not C.visible(v) or not love.mouse then return false end
local x,y=love.mouse.getPosition();if not C.point(v,x,y) then return false end
local s=C.state(v);s.zoom=clamp(s.zoom*math.exp(-(dy or 0)*.12),.45,2.1)
return true
end
function C.update(v)
if not C.visible(v) then if v then v.drag=nil end;return end
if not love.mouse or not love.keyboard then return end
local s=C.state(v);local mx,my=love.mouse.getPosition()
local touch=love.touch and love.touch.getTouches() or {}
local mode,dist
if #touch>0 then
mx,my=love.touch.getPosition(touch[1]);mode='orbit'
if #touch>1 then local x,y=love.touch.getPosition(touch[2]);dist=math.sqrt((mx-x)^2+(my-y)^2);mx,my=(mx+x)/2,(my+y)/2;mode='touchpan' end
elseif love.mouse.isDown(3) then mode='pan'
elseif love.mouse.isDown(1) or love.mouse.isDown(2) then
mode=love.keyboard.isDown('lshift','rshift') and 'zoom' or 'orbit'
end
local home=love.keyboard.isDown('home')
if home and not v.home and C.point(v,mx,my) then v.camera=nil;s=C.state(v) end
v.home=home
local drag=v.drag
if mode and (drag or C.point(v,mx,my)) then
if drag and drag.mode==mode then
local dx,dy=(mx-drag.x)/v.viewport.w,(my-drag.y)/v.viewport.h
if mode=='orbit' then s.yaw=s.yaw-dx*math.pi*2;s.pitch=clamp(s.pitch+dy*2.8,-1.05,1.3)
elseif mode=='zoom' then s.zoom=clamp(s.zoom*math.exp(dy*3),.45,2.1)
else s.panX=clamp(s.panX-dx*28,-18,18);s.panY=clamp(s.panY+dy*28,-18,18)
if dist and drag.dist and dist>1 then s.zoom=clamp(s.zoom*drag.dist/dist,.45,2.1) end
end
end
v.drag={x=mx,y=my,mode=mode,dist=dist}
else v.drag=nil end
end
function C.pose(v,distance)
local s=C.state(v);local d=distance*s.zoom
local base=v.modelFocus or {0,9,0}
local focus={base[1]+s.panX,base[2]+s.panY,base[3]}
return {focus[1],focus[2]+math.sin(s.pitch)*d,focus[3]+math.cos(s.pitch)*d},focus,s.yaw
end
return C
