

local V=...
local req=V.engineRequire or require
local S={canvases={},fonts={},portraits={}}
local readyFonts=setmetatable({},{__mode='k'})
local uiGlyphs={}
for code=32,126 do uiGlyphs[#uiGlyphs+1]=string.char(code) end
uiGlyphs=table.concat(uiGlyphs)..'éÉ…—–←→↑↓♂♀×'
local function readyFont(font)
if not readyFonts[font] then


local warm=love.graphics.newText(font,uiGlyphs);warm:release();readyFonts[font]=true
end
return font
end
local function G() return love.graphics end
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
function S.font(size)
size=math.max(8,math.floor(size+.5))
if V.ColosseumFont then
local f=V.ColosseumFont.font(size,'linear')
if f then return readyFont(f) end
end
if not S.fonts[size] then
local f=G().newFont(size,'normal',1);f:setFilter('linear','linear');S.fonts[size]=f
end
return readyFont(S.fonts[size])
end
function S.text(value,x,y,w,h,size,color,align)
local g=G();value=tostring(value or '')
local f=S.font(size);local tw,th=f:getWidth(value),f:getHeight()
local k=math.min(1,w/math.max(1,tw),h/math.max(1,th))
if align=='right' then x=x+w-tw*k
elseif align=='center' then x=x+(w-tw*k)/2 end
y=y+(h-th*k)/2
g.setFont(f);g.setColor(0,0,0,.75);g.print(value,math.floor(x+1),math.floor(y+1),0,k,k)
g.setColor(color or {.94,.94,.85,1});g.print(value,math.floor(x),math.floor(y),0,k,k)
end

local panelContext={}
local statusContext={}
function panelContext.setUIColor(_,...) panelContext.g.setColor(...) end
function statusContext.setUIColor(role,...)
if role=='trim' then statusContext.g.setColor(.77,.69,.39,.95) else statusContext.g.setColor(...) end
end
local function hudContext()
panelContext.g=G()
return panelContext
end
function S.panel(x,y,w,h,u,status)
local ctx=status and statusContext or panelContext;ctx.g=G()
V.UIPresentation.consolePanel(ctx,x,y,w,h,u)
end
function S.select(x,y,w,h,u)
local g=G();g.setColor(.33,.35,.32,.85)
g.polygon('fill',x+8*u,y,x+w-5*u,y,x+w,y+h,x+8*u,y+h)
g.setColor(.90,.23,.13,1);g.polygon('fill',x-4*u,y+h*.28,x+4*u,y+h*.5,x-4*u,y+h*.72)
end
function S.present(key,draw,background)
if V.Gen3Overlay then V.Gen3Overlay.reset() end
local g=G();local R=req('src.render.Renderer');local D=req('src.core.game3.display')
local target=g.getCanvas()
local high=not D.planesBroken and target and target==R.canvas and type(R.frameRects)=='function'
local r=high and R:frameRects() or nil
local w,h=high and math.max(1,math.floor(r.pw)) or 240,high and math.max(1,math.floor(r.ph)) or 160
local c=S.canvases[key]
if high and (not c or c:getWidth()~=w or c:getHeight()~=h) then
if c then c:release() end
c=g.newCanvas(w,h,{dpiscale=1});c:setFilter('linear','linear');S.canvases[key]=c
end
g.push('all')
if high then g.setCanvas({c,depth=true}) end
g.origin();g.setShader();g.setDepthMode();g.setScissor();g.setBlendMode('alpha')
g.clear(.025,.038,.044,1,0,1)
if background then
g.setColor(1,1,1,1);g.draw(background,0,0,0,w/background:getWidth(),h/background:getHeight())
end
draw(w,h)
g.pop()
if high then R:setWorldOverride(c);g.clear(0,0,0,0) end
return true,high
end
function S.portraitPath(mon)
local dex,variant=V.ModelIdentity.resolve(V.mod.game,mon)
return dex and V.ColosseumPortraitCatalog.assetPath(dex,1,variant=='shiny') or nil
end
local function portrait(mon,x,y,w)
local path=S.portraitPath(mon)
if not path then return false end
local image=S.portraits[path]
if image==nil then
local bytes=V.mod.read and V.mod:read(path)
if bytes then
local ok,result=pcall(function()
local fd=love.filesystem.newFileData(bytes,path)
local img=G().newImage(love.image.newImageData(fd));img:setFilter('linear','linear');return img
end)
image=ok and result or false
else image=false end
S.portraits[path]=image
end
if image then local g=G();g.setColor(1,1,1,1);g.draw(image,x,y,0,w/image:getWidth(),w/image:getHeight()) end
return image and true or false
end
S.drawPortrait=portrait
function S.portraitPod(mon,x,y,size,u)
local ctx=hudContext()
V.UIPresentation.portraitPod(ctx,x,y,size,u)
portrait(mon,x+1.8*u,y+1.8*u,size-3.6*u)

V.UIPresentation.portraitPodOverlay(ctx,x,y,size,u)
end
function S.battleGender(mon)
local P=req('src.core.game3.pokemon')
if not mon or P.isEgg(mon) then return nil end
local gender=P.gender(P.speciesOf(mon),mon.personality or 0)
return gender=='M' and 'male' or gender=='F' and 'female' or nil
end
function S.moveTypeName(mon,slot)
local move=mon and mon.moves and mon.moves[slot]
if not move or move==0 then return '—' end
local def=req('src.core.game3.battle.moves').get(move)
local name=def and req('src.core.game3.battle.types').name(def.type)
return name and S.decodeText(name) or '—'
end
local symbols={[0x53]='POKé',[0x54]='MON',[0x55]='POKé',[0x56]='B',
[0x57]='L',[0x58]='O',[0x59]='CK',[0x34]='Lv',[0x2c]='er',
[0x84]='e',[0xa0]='re',[0x77]=' ',[0x79]='↑',[0x7a]='↓',[0x7b]='←',[0x7c]='→'}
local labels={[0]='A',[1]='B',[2]='L',[3]='R',[4]='START',[5]='SELECT',
[6]='UP',[7]='DOWN',[8]='LEFT',[9]='RIGHT',[10]='UP/DOWN',[11]='LEFT/RIGHT',[12]='D-PAD'}
function S.decodeText(value,limit)
local F=req('src.ui.game3.frlg_font');local out={};local n=0
for kind,value in F.scanTokens(value or '') do
if n>=(limit or math.huge) then break end
if kind=='char' then out[#out+1]=value;n=n+1
elseif kind=='nl' then out[#out+1]='\n';n=n+1
elseif kind=='glyph' then

out[#out+1]=symbols[value] or (F.LATIN_GLYPHS and F.LATIN_GLYPHS[value]) or '?';n=n+1
elseif kind=='icon' then

out[#out+1]='['..(labels[value] or '?')..']';n=n+1
end
end
return table.concat(out)
end
function S.messageText(Message)
return S.decodeText(Message.currentPage(),Message._revealed or 0)
end
function S.ownsBattleMessage(Message)
local painted=S.battleMessagePainted
if not painted or not Message.open or painted.pages~=Message._pages
or painted.page~=Message._page or painted.revealed~=Message._revealed
or painted.waiting~=Message._waiting or painted.held~=Message._held then return false end
local R=req('src.render.Renderer')
if painted.high then return R.worldOverride==painted.canvas end
return G().getCanvas()==painted.canvas and R.worldOverride==nil
end
function S.battleDialogueLayout(w,h,source,padBottom)
local raw=math.min(w/1280,h/720)


local u=(w<=320 or h<=200) and raw or clamp(raw,.72,1.75)
local margin=clamp(20*u,10,42)
local width=math.min(w-margin*2,clamp(940*u,400,1540))
local inset=clamp(32*u,12,56)
local contentW=math.max(1,width-inset*2-clamp(28*u,14,46))
local size=clamp(30*u,(w<=320 or h<=200) and 8 or 20,46)
local font=S.font(size)
local _,rows=font:getWrap(source or '',contentW)
local minH=clamp(130*u,(w<=320 or h<=200) and 25 or 88,220)
local height=math.max(minH,#rows*font:getHeight()+clamp(44*u,22,72))
local bottom=padBottom or clamp(24*u,12,42)
local available=math.max(1,h-bottom-margin)
while height>available and size>8 do
size=size-1;font=S.font(size)
_,rows=font:getWrap(source or '',contentW)
height=math.max(minH,#rows*font:getHeight()+clamp(44*u,22,72))
end
height=math.min(height,available)
return {x=(w-width)*.5,y=h-height-bottom,w=width,h=height,
u=u,font=font,fontSize=size,inset=inset,contentW=contentW}
end
function S.releaseBattleBackdrop()
if S.battleBackdrop then S.battleBackdrop:release();S.battleBackdrop=nil end
S.battleFrameReady=false
end
function S.captureBattleBackdrop()
S.releaseBattleBackdrop()
if not (love and love.graphics and love.graphics.newCanvas) then return end
local source=req('src.render.GameViewport').canvas
if not source then return end
local g=G();local w,h=source:getDimensions()
S.battleBackdrop=g.newCanvas(w,h,{dpiscale=1})
g.push('all');g.setCanvas(S.battleBackdrop);g.origin();g.setShader();g.setScissor();g.setDepthMode()
g.clear(0,0,0,1);g.setColor(1,1,1,1);g.setBlendMode('alpha','premultiplied');g.draw(source);g.pop()
end
function S.waitForBattleModels()
S.battleMessagePainted=nil
local R=V.Gen3Runtime
local source=S.battleFrameReady and S.canvases.battle or S.battleBackdrop
local _,high=S.present('battle-ready',function(w,h)
if R.modelError or (R.holdSeconds or 0)>.75 then
local u=math.min(w/1280,h/720);local mw=760*u;local x,y=(w-mw)/2,h-122*u
S.panel(x,y,mw,94*u,u)
S.text(R.modelError and 'MODEL PREPARATION FAILED' or 'PREPARING BATTLE MODELS',x+22*u,y+13*u,mw-44*u,24*u,20*u)
S.text(R.modelError or 'Preparing '..tostring(R.missingModels or 0)..' source models before the battle begins.',
x+22*u,y+43*u,mw-44*u,19*u,14*u)
if R.modelError then S.text('A  Retry     B  Use native artwork for this battle',x+22*u,y+67*u,mw-44*u,17*u,13*u) end
end
end,source)
S.battlePainted=high and S.canvases['battle-ready'] or nil
return true
end
function S.battleStatus(mon)
local value=mon and mon.status
if type(value)=='string' then return value~='' and value~='NONE' and value:upper() or nil end
value=tonumber(value) or 0
if value%8>0 then return 'SLP' end
if math.floor(value/8)%2==1 or math.floor(value/128)%2==1 then return 'PSN' end
if math.floor(value/16)%2==1 then return 'BRN' end
if math.floor(value/32)%2==1 then return 'FRZ' end
if math.floor(value/64)%2==1 then return 'PAR' end
end
function S.battle(f,ui,background)
S.battleMessagePainted=nil
local painted
local _,high=S.present('battle',function(w,h)
local g=G();local u=math.min(w/1280,h/720)
local margin=24*u


local UIP=V.UIPresentation
local padBottom=UIP and UIP.isMobile and UIP.isMobile() and (UIP.bottomReserve(w,h,nil,'battle')+math.max(3,4*u)) or margin
local P=req('src.core.game3.pokemon');local Anim=req('src.core.game3.battle.anim')
do
local u=u*1.2
local margin=24*u;local cardW=248*u;local pod=44*u
local stage=Anim.stage()
for id=0,(f.double and 3 or 1) do
local b=f.battlers[id];local hb=stage and stage.healthbox and stage.healthbox[id]
if b and not b.absent and (not hb or hb.visible~=false)
and not (V.Gen3Capture and V.Gen3Capture.captured(id)) then
local player=id%2==0
local cardH=(player and 62 or 52)*u
local row=f.double and (player and math.floor(id/2) or (id==1 and 1 or 0)) or 0
local x=player and margin or w-margin-cardW-pod-5*u
local y=margin+row*76*u
local ratio,hp,max=Anim.displayHpRatio(id,b.native)
ratio=clamp(ratio or 0,0,1)
local py=y+(cardH-pod)/2
S.panel(x,y,cardW,cardH,u,true)
S.portraitPod(b.mon,x+cardW+5*u,py,pod,u)
if (ui._mode=='target' and ui._target and ui._target.cursor==id) then
g.setColor(1,.40,.17,1);g.setLineWidth(2*u);g.rectangle('line',x-2*u,y-2*u,cardW+pod+9*u,cardH+4*u)
end
local exp,level
if player then exp,level=Anim.displayExpRatio(id,b.native) end
local gender=S.battleGender(b.mon);local name=P.displayMonName(b.mon)
local nameWidth=cardW-(gender and 101 or 79)*u
S.text(name,x+12*u,y+6*u,nameWidth,21*u,19*u)
if gender then
local font=S.font(19*u)
local inkWidth=font:getWidth(name)*math.min(1,nameWidth/math.max(1,font:getWidth(name)),21*u/font:getHeight())
V.UIPresentation.genderGlyph(hudContext(),x+12*u+inkWidth+6*u,y+12*u,11*u,gender)
end
S.text('Lv '..tostring(level or b.mon.level),x+cardW-66*u,y+6*u,52*u,21*u,16*u,nil,'right')
S.text('HP',x+12*u,y+28*u,23*u,12*u,11*u,{.88,.75,.35,1})
local bx,by,bw=x+39*u,y+32*u,cardW-53*u
g.setColor(.04,.05,.045,1);g.rectangle('fill',bx-1,by-1,bw+2,7*u)
if ratio>.5 then g.setColor(.19,.78,.31,1) elseif ratio>.2 then g.setColor(.96,.7,.09,1) else g.setColor(.9,.22,.17,1) end
g.rectangle('fill',bx,by,bw*ratio,5*u)
if player then
S.text(math.floor(hp or 0)..' / '..tostring(max or 1),x+cardW-97*u,y+40*u,83*u,11*u,10*u,nil,'right')
S.text('EXP',x+12*u,y+50*u,23*u,9*u,8*u,{.56,.76,.92,1})
g.setColor(.11,.18,.23,1);g.rectangle('fill',bx,y+54*u,bw,3*u)
g.setColor(.32,.67,.94,1);g.rectangle('fill',bx,y+54*u,bw*clamp(exp or 0,0,1),3*u)
end
local status=S.battleStatus(b.mon)
if status then
S.text(status,x+12*u,y+40*u,75*u,11*u,10*u,{1,.72,.3,1})
end
end
end
end
local active=f.battlers[ui._active or 0] or f.player
local M=req('src.ui.game3.message')
local mode=ui._mode


if M.isOpen() and (not M._held or req('src.ui.game3.choice').active) then mode='message' end
local mh=(mode=='moves' or mode=='target') and 132*u or 100*u
local mw=(mode=='moves' or mode=='target') and 820*u or 690*u
local x,y=(w-mw)/2,h-mh-padBottom
if mode=='menu' or mode=='moves' or mode=='target' then
S.panel(x,y,mw,mh,u)
local pad=25*u;local info=(mode=='menu') and 0 or 180*u
local cw=(mw-pad*2-info)/2;local rh=(mh-22*u)/2
for i=1,4 do
local cx,cy=x+pad+((i-1)%2)*cw,y+11*u+math.floor((i-1)/2)*rh
local selected=i==(mode=='menu' and ui._menuIndex or ui._moveIndex)
if selected then S.select(cx,cy,cw-10*u,rh-3*u,u) end
local move=active and active.mon.moves and active.mon.moves[i]
local value=mode=='menu' and ({'FIGHT','BAG','POKéMON','RUN'})[i] or (move and move~=0 and P.moveName(move) or '—')
S.text(value,cx+14*u,cy+4*u,cw-32*u,rh-10*u,24*u,
selected and {.97,.94,.76,1} or {.76,.79,.72,1})
end
if mode~='menu' then
local slot=ui._moveIndex or 1;local mon=active.mon
local label=mode=='target' and 'TARGET' or 'PP'
local labelWidth=math.min(84*u,S.font(20*u):getWidth(label))
S.text(label,x+mw-info,y+25*u,labelWidth,24*u,20*u)
S.text(S.moveTypeName(mon,slot),x+mw-info+labelWidth+12*u,y+25*u,
info-36*u-labelWidth,24*u,16*u,{.88,.75,.35,1},'right')
S.text(tostring(mon.pp and mon.pp[slot] or 0)..' / '..tostring(mon.maxPp and mon.maxPp[slot] or 0),
x+mw-info,y+64*u,info-24*u,25*u,23*u)
end
else
if M.isOpen() then



painted={pages=M._pages,page=M._page,revealed=M._revealed,
waiting=M._waiting,held=M._held}
local value=S.messageText(M)
local rect=S.battleDialogueLayout(w,h,
S.decodeText(M.currentPage() or ''),padBottom)
if V.Gen3Overlay then V.Gen3Overlay.dialogueRect=rect end
S.panel(rect.x,rect.y,rect.w,rect.h,rect.u)
g.setFont(rect.font);g.setColor(.94,.94,.85,1)
g.setScissor(rect.x+rect.inset,rect.y+8*rect.u,
rect.contentW,rect.h-16*rect.u)
g.printf(value,rect.x+rect.inset,rect.y+20*rect.u,rect.contentW,'left')
g.setScissor()
if M._waiting and not M._held then
local cx=rect.x+rect.w-30*rect.u
local cy=rect.y+rect.h-27*rect.u
g.setColor(.9,.23,.13,1)
g.polygon('fill',cx,cy,cx+12*rect.u,cy,cx+6*rect.u,cy+8*rect.u)
end
end
end
end,background)
S.battlePainted=high and S.canvases.battle or nil
if painted then
painted.high=high;painted.canvas=high and S.canvases.battle or G().getCanvas()
S.battleMessagePainted=painted
end
S.battleFrameReady=true
return true
end
function S.releaseStarter()
if S.starter then for _,r in ipairs(S.starter.rows) do if r.actor then r.actor:release() end end end
if V.PokemonActors.cancelInformation then V.PokemonActors.cancelInformation() end
S.starter=nil
end
function S.prepareStarter(screen,dt)
if S.starter and S.starter.preview then
S.starter.screen=screen;S.starter.preview=screen==S.starterPrefetch
elseif not S.starter or S.starter.screen~=screen then
S.releaseStarter()
local rows={}
for _,sp in ipairs(screen.man.species) do
rows[#rows+1]={mon={species=sp,speciesNumbering='internal',isShiny=false}}
end
S.starter={screen=screen,rows=rows,clock=0}
end
local state=S.starter;state.clock=state.clock+(dt or 1/60)
if V.ResidentPrewarm and V.ResidentPrewarm.touchViewer then V.ResidentPrewarm.touchViewer(.2,'starter-models') end


local pending=state.pending
if not pending then
if not state.rows[screen.selection+1].actor then pending=screen.selection+1 end
if not pending then for i,r in ipairs(state.rows) do if not r.actor then pending=i;break end end end
end
if pending then
state.pending=pending;local r=state.rows[pending]
local ready,why,busy=V.PokemonActors.pumpInformation(V.mod.game,{mon=r.mon},'body')
r.error=not busy and not ready and why or nil
if ready then
local dex,variant=V.ModelIdentity.resolve(V.mod.game,r.mon)
r.actor,r.error=V.PokemonActors.acquireCached('cbe-gen3-starter',dex,variant,
{context={game=V.mod.game,arena={figureScale=1},services={informationSurface=true}},battler={mon=r.mon},noSource=true})
if r.actor then r.actor.worldScale=12/math.max(.1,r.actor.height or 16);r.actor:spawn(1);r.actor:idle() end
state.pending=nil
elseif not busy then state.pending=nil end
end
for _,r in ipairs(state.rows) do if r.actor then r.actor:update(dt or 1/60) end end
end
local function stageMesh()
if S.stageMesh then return end
local verts={}
local function v(x,y,z,c) return {x,y,z,c[1]/255,c[2]/255,c[3]/255,1} end
for _,cx in ipairs({-17,0,17}) do
for i=0,63 do
local a,b=i*math.pi/32,(i+1)*math.pi/32
local x,z=cx+7*math.cos(a),7*math.sin(a)
local nx,nz=cx+7*math.cos(b),7*math.sin(b)
local top={57,72,72};local side={24,34,36}
for _,p in ipairs({v(cx,0,0,top),v(x,0,z,top),v(nx,0,nz,top),
v(x,0,z,side),v(x,-1.5,z,side),v(nx,0,nz,side),
v(nx,0,nz,side),v(x,-1.5,z,side),v(nx,-1.5,nz,side)}) do verts[#verts+1]=p end
end
end
S.stageMesh=G().newMesh({{'VertexPosition','float',3},{'VertexColor','byte',4}},verts,'triangles','static')
S.stageShader=G().newShader([[vec4 effect(vec4 c,Image t,vec2 uv,vec2 p){return c;}]],
[[uniform mat4 vp; vec4 position(mat4 t,vec4 p){return vp*p;}]])
end
function S.starterDraw(screen)
return S.present('starter',function(w,h)
local g=G();local u=math.min(w/1280,h/720)
local state=S.starter;local P=req('src.core.game3.pokemon')
local eye,focus={0,18,63},{0,5,0}
local vp=V.Mat4.mul(V.Mat4.perspective(math.rad(42),w/h,.1,300),V.Mat4.lookAt(eye,focus,{0,1,0}))
vp=V.Mat4.mul(V.Mat4.scale(1,-1,1),vp)
stageMesh();g.setShader(S.stageShader);S.stageShader:send('vp','row',vp)
g.setDepthMode('lequal',true);g.setMeshCullMode('none');g.setColor(1,1,1,1);g.draw(S.stageMesh)
g.setShader();g.setDepthMode()
if state then
V.PokemonActors.service.withRenderer(vp,function()
for i,r in ipairs(state.rows) do if r.actor then
r.actor:draw(r.actor:matrix((i-2)*17,0,0,math.sin(.25),math.cos(.25)))
end end
return true
end,{eye=eye,focus=focus,width=w,height=h,context={services={informationSurface=true}}})
end
S.text('Choose your Pokémon',40*u,24*u,w-80*u,44*u,32*u,nil,'center')
for i,sp in ipairs(screen.man.species) do
local x=w/2+(i-2)*w*.232-110*u;local y=h*.67
S.panel(x,y,220*u,48*u,u,i==screen.selection+1)
if i==screen.selection+1 then S.select(x+10*u,y+9*u,200*u,30*u,u) end
S.text(P.name(sp),x+20*u,y+8*u,180*u,32*u,24*u,nil,'center')
if state and not state.rows[i].actor then
S.text(state.rows[i].error and 'Model unavailable' or 'Preparing model…',x,y-45*u,220*u,25*u,16*u,nil,'center')
end
end
local x,mw,mh=w*.12,w*.76,96*u;local y=h-mh-24*u
S.panel(x,y,mw,mh,u)
local prompt=screen.confirm and ('Choose '..P.name(screen.mon.species)..'?')
or 'Prof. Birch needs help. Choose a Pokémon to rescue him.'
S.text(prompt,x+24*u,y+14*u,mw-(screen.confirm and 230*u or 48*u),36*u,23*u)
if screen.confirm then
for i,value in ipairs({'YES','NO'}) do
local cx=x+mw-200*u+(i-1)*90*u
if screen.confirm.cursor==i-1 then S.select(cx,y+20*u,80*u,34*u,u) end
S.text(value,cx+10*u,y+20*u,65*u,34*u,23*u)
end
end
S.text(screen.confirm and 'A  Confirm     B  Back' or 'LEFT / RIGHT  Choose     A  View',
x+24*u,y+57*u,mw-48*u,23*u,16*u,{.64,.71,.69,1})
req('src.ui.game3.rse.scene_kit').drawFade(screen.pal,0,w,h)
end)
end
function S.pump(dt)
if S.starter and not S.starter.preview then


S.prepareStarter(S.starter.screen,math.max(0,math.min(.1,tonumber(dt) or 0)))
return
end
if S.starterPrefetch and not (S.starter and not S.starter.preview) then
S.prepareStarter(S.starterPrefetch,dt)
S.starter.preview=true
local ready=true
for _,row in ipairs(S.starter.rows) do if not row.actor then ready=false;break end end


if ready then S.starterPrefetch=nil end
end
end
function S.cancelPrefetch()
S.starterPrefetch=nil
if S.starter and S.starter.preview then S.releaseStarter() end
end
function S.install()
local ok,Starter=pcall(req,'src.ui.game3.rse.starter_choose')
if ok and Starter then
local new,frame,reset=Starter.new,Starter.frame,Starter.reset
Starter.new=function(opts)
local screen=new(opts);S.prepareStarter(screen,0);S.starterPrefetch=nil
return screen
end
Starter.frame=function(self,...)
local result=frame(self,...)
if result then S.releaseStarter()
elseif not (V.FrameWork and V.FrameWork.active(V.Gen3Runtime and V.Gen3Runtime.game or V.mod.game)) then
S.prepareStarter(self,1/60)
end
return result
end
Starter.draw=function(self) return S.starterDraw(self) end
Starter.reset=function(...) S.releaseStarter();return reset(...) end



for _,path in ipairs({'src.ui.game3.rse.birch_speech','src.ui.game3.rs.birch_speech'}) do
local found,Birch=pcall(req,path)
if found then local birchNew=Birch.new
Birch.new=function(...)
local result=birchNew(...)
local P=req('src.core.game3.pokemon')
S.starterPrefetch={selection=1,man={species={P.speciesFromNational(252),P.speciesFromNational(255),P.speciesFromNational(258)}}}
return result
end
end
end
end
end
return S
