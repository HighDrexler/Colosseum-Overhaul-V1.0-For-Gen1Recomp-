


local V=...
local req=V.engineRequire or require
local O={active=false}
local function graphics() return love.graphics end
function O.reset()
O.active=false;O.dialogueRect=nil;O.namingPainted=nil
if V.Gen3Screens then V.Gen3Screens.battleMessagePainted=nil end
end
function O.available()
local R=req('src.render.Renderer')
return not req('src.core.game3.display').planesBroken
and graphics().getCanvas()==R.canvas and type(R.frameRects)=='function'
end
local function neutral(g)
g.origin();g.setShader();g.setDepthMode();g.setScissor();g.setColor(1,1,1,1)
end
function O.flush()
if not O.active then return end
local g=graphics();local R=req('src.render.Renderer');local r=O.rect
g.push('all');g.setCanvas(O.canvas);neutral(g)
g.setBlendMode('alpha','premultiplied')
g.draw(R.canvas,(r.uox-r.vux)*r.dpiX,(r.uoy-r.vuy)*r.dpiY,0,r.Ux*r.dpiX,r.Uy*r.dpiY)
g.setCanvas(R.canvas);g.clear(0,0,0,0);g.pop()
end
function O.paint(draw)
if not O.available() then return false end
local g=graphics();local R=req('src.render.Renderer');local r=R:frameRects()
local w,h=math.max(1,math.floor(r.pw)),math.max(1,math.floor(r.ph))
if not O.canvas or O.canvas:getWidth()~=w or O.canvas:getHeight()~=h then
local c=g.newCanvas(w,h,{dpiscale=1});c:setFilter('linear','linear')
if O.canvas then O.canvas:release() end
O.canvas=c;O.active=false
end
O.rect=r
if not O.active then
g.push('all');g.setCanvas(O.canvas);neutral(g);g.clear(0,0,0,0);g.pop()
O.active=true
end
O.flush()
g.push('all');g.setCanvas(O.canvas);neutral(g);g.setBlendMode('alpha')
local ok,err=pcall(draw,w,h,r)
g.pop()
if not ok then error(err,0) end
return true
end
function O.install()
if O.installed then return end
local R=req('src.render.Renderer')
local begin,finish,blit=R.beginFrame,R.endFrame,R.blitCanvas
R.beginFrame=function(self,...)
O.reset();return begin(self,...)
end
R.endFrame=function(self,...)
O.flush()
local result={pcall(finish,self,...)}
O.reset()
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
R.blitCanvas=function(self,canvas,...)
if not O.active or canvas~=self.canvas then return blit(self,canvas,...) end
local g=graphics();local r=O.rect
g.push('all');neutral(g);g.setBlendMode('alpha','premultiplied')
g.setScissor(r.vux,r.vuy,r.vuw,r.vuh)
g.draw(O.canvas,r.vux,r.vuy,0,1/r.dpiX,1/r.dpiY);g.pop()
end
O.installed=true
end
return O
