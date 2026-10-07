


local V=...
local req=V.engineRequire or require
local S={rows={},installed=false}
local DEX={ [1]=true,[4]=true,[7]=true }
local ORDER={1,4,7}
local function G() return love.graphics end
local function game() return V.Gen3Runtime.game or V.mod.game end
local function lab()
local g=game();local session=g and V.Gen3Runtime.session(g)
local map=session and session.map
return map=='FR_OAKS_LAB' or map=='PalletTown_ProfessorOaksLab'
end
local function release()
for _,row in pairs(S.rows) do if row.actor then row.actor:release() end end
S.rows={};S.pending=nil
if S.canvas then S.canvas:release();S.canvas=nil end
end
local function rowFor(dex)
local row=S.rows[dex]
if row then return row end
local P=req('src.core.game3.pokemon')
row={dex=dex,mon={species=P.speciesFromNational(dex),speciesNumbering='internal',isShiny=false}}
S.rows[dex]=row
return row
end
function S.pump(dt)
if not lab() then
if next(S.rows) then release() end
return
end
if V.Gen3UI.viewer then return end
local A=V.PokemonActors
if not (A and A.pumpInformation and A.acquireCached) then return end
local Pic=req('src.ui.game3.mon_pic')
local selected=Pic.active and DEX[Pic.species] and Pic.species or nil
local session=V.Gen3Runtime.session(game())
if not selected and session and session.party and #session.party>0 then
if next(S.rows) then release() end
return
end
local pending=S.pending
if not pending then
if selected then
local row=rowFor(selected)
if not row.actor and (row.retryAt or 0)<=(S.clock or 0) then pending=selected end
end
if not pending then
for _,dex in ipairs(ORDER) do
local row=rowFor(dex)
if not row.actor and (row.retryAt or 0)<=(S.clock or 0) then pending=dex;break end
end
end
end
if pending then
if V.ResidentPrewarm and V.ResidentPrewarm.touchViewer then
V.ResidentPrewarm.touchViewer(.2,'frlg-starter-models')
end
S.pending=pending
local row=rowFor(pending)
local ready,why,busy=A.pumpInformation(game(),{mon=row.mon},'body')
row.error=not busy and not ready and why or nil
if ready then
local dex,variant=V.ModelIdentity.resolve(game(),row.mon)
row.actor,row.error=A.acquireCached('cbe-frlg-starter',dex,variant,
{context={game=game(),arena={figureScale=1},services={informationSurface=true}},
battler={mon=row.mon},noSource=true})
if row.actor then
row.actor.worldScale=18/math.max(.1,row.actor.height or 16)
row.actor:spawn(1);row.actor:idle()
else
row.retryAt=(S.clock or 0)+2
end
S.pending=nil
elseif not busy then
S.pending=nil;row.retryAt=(S.clock or 0)+2
end
end
for _,row in pairs(S.rows) do if row.actor then row.actor:update(dt or 1/60) end end
end
local function modelCanvas(w,h)
local g=G();local cw,ch=math.max(1,math.ceil(w)),math.max(1,math.ceil(h))
if not S.canvas or S.canvas:getWidth()~=cw or S.canvas:getHeight()~=ch then
if S.canvas then S.canvas:release() end
S.canvas=g.newCanvas(cw,ch,{dpiscale=1})
S.canvas:setFilter('linear','linear')
end
return S.canvas,cw,ch
end
local function drawModel(row,x,y,w,h)
if not row.actor then return false end
local g=G();local canvas,cw,ch=modelCanvas(w,h)
local actor=row.actor
local bounds=actor.scene and actor.scene.bounds
local span=actor.height or 16
if bounds and bounds.min and bounds.max then
span=math.max(span,bounds.max[1]-bounds.min[1],bounds.max[3]-bounds.min[3])
end
local scale=actor.worldScale or 1
local radius=span*scale*.62
local center=9
if bounds and bounds.min and bounds.max then
local lo,hi=bounds.min,bounds.max
local rx=math.max(math.abs(lo[1]),math.abs(hi[1]))
local rz=math.max(math.abs(lo[3]),math.abs(hi[3]))
radius=math.sqrt(rx*rx+rz*rz+((hi[2]-lo[2])*.5)^2)*scale
center=((lo[2]+hi[2])*.5+math.max(0,-(actor.scene.floorMinY or lo[2])))*scale
end
local halfFov=math.atan(math.tan(math.rad(20))*math.min(1,cw/ch))
local distance=math.max(33,radius/math.sin(halfFov)*1.12)
local eye,focus={0,center+distance*.13,distance},{0,center,0}
local vp=V.Mat4.mul(V.Mat4.perspective(math.rad(40),cw/ch,.1,
math.max(300,distance*3.2+radius*2)),
V.Mat4.lookAt(eye,focus,{0,1,0}))
vp=V.Mat4.mul(V.Mat4.scale(1,-1,1),vp)
local target=g.getCanvas()
g.push('all');g.setCanvas({canvas,depth=true});g.origin();g.setShader()
g.clear(0,0,0,0,0,1)
local ok,err=pcall(function()
V.PokemonActors.service.withRenderer(vp,function()
actor:draw(actor:matrix(0,0,0,math.sin(.22),math.cos(.22)))
return true
end,{eye=eye,focus=focus,width=cw,height=ch,
context={services={informationSurface=true}}})
end)
g.setCanvas(target);g.pop()
if not ok then row.error=tostring(err);return false end
g.setColor(1,1,1,1)
g.draw(canvas,x,y,0,w/cw,h/ch)
return true
end
function S.draw(Pic)
local O=V.Gen3Overlay
local S3=V.Gen3Screens
local row=rowFor(Pic.species)
return O.paint(function(w,h)
local u=math.min(w/1280,h/720)
local width=math.min(w*.37,440*u)
local height=math.min(h*.56,405*u)
local x=math.max(16*u,math.min(w-width-16*u,(Pic.left or 10)*8*w/240))
local y=math.max(16*u,math.min(h-height-16*u,(Pic.top or 3)*8*h/160))
S3.panel(x,y,width,height,u)
local pad=15*u;local artH=height-66*u
if not drawModel(row,x+pad,y+pad,width-2*pad,artH) then
S3.text((row.error or S.error) and 'MODEL UNAVAILABLE' or 'PREPARING 3D MODEL',
x+pad,y+height*.42,width-2*pad,32*u,18*u,{.75,.82,.79,1},'center')
end
local P=req('src.core.game3.pokemon')
S3.text(P.name(row.mon.species),x+pad,y+height-47*u,width-2*pad,31*u,23*u,nil,'center')
end)
end
function S.install()
if S.installed then return end
local Pic=req('src.ui.game3.mon_pic')
local nativeDraw=Pic.draw
Pic.draw=function(...)
if not (Pic.active and DEX[Pic.species] and lab() and V.Gen3Overlay.available()) then
return nativeDraw(...)
end
return S.draw(Pic)
end
local U=V.Gen3UI;local pump=U.pump
U.pump=function(dt,...)
S.clock=(S.clock or 0)+(dt or 1/60)
local result={pump(dt,...)}
local ok,err=pcall(S.pump,dt)
S.error=not ok and tostring(err) or nil
return unpack(result)
end
S.installed=true
end
S._test={lab=lab,release=release,rowFor=rowFor,starter=DEX}
return S
