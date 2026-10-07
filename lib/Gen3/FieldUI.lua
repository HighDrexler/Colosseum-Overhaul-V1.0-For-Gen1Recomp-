

local V=...
local req=V.engineRequire or require
local F={}
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local function lines(s)
local out={};for row in (tostring(s or '')..'\n'):gmatch('(.-)\n') do out[#out+1]=row end
return out
end
function F.context(w,h)
local g=love.graphics;local S=V.Gen3Screens
return {g=g,dimensions=function() return w,h end,
scale=function() return clamp(math.min(w/1280,h/720),.72,1.75) end,
boxScale=function() return 1 end,textScale=function() return 1.08 end,
textWeight=function() return 0 end,font=S.font,
measure=function(font,s) return font:getWidth(s) end,
roundedRect=function(mode,x,y,cw,ch,r) return g.rectangle(mode,x,y,cw,ch,r,r) end,
setUIColor=function(_,...) g.setColor(...) end,
text=function(value,x,y,size,color,align,width)
g.setFont(S.font(size));g.setColor(0,0,0,(color[4] or 1)*.753)
if width then g.printf(value,x+1,y+1,width,align or 'left') else g.print(value,x+1,y+1) end
g.setColor(color)
if width then g.printf(value,x,y,width,align or 'left') else g.print(value,x,y) end
end}
end
function F.dialogue(shown,source,waiting,frame,opts)
return V.Gen3Overlay.paint(function(w,h)
local ctx=F.context(w,h);ctx.dialogueLift=18*ctx.scale();ctx.dialogueTextScale=1.25


ctx.dialogueAllRows=true
ctx.dialogueSlide=opts and opts.slide
V.Gen3Overlay.dialogueRect=V.UIPresentation.compactDialogue(ctx,shown,source,waiting,frame)
end)
end
function F.message(M)
local S=V.Gen3Screens
local Chrome=req('src.ui.game3.chrome')
local arrow=Chrome.arrowSpec and Chrome.arrowSpec()
local prompt=not M._stay
if arrow then prompt=arrow.lastPage or M._page<#M._pages end
local waiting=M._waiting and not M._held and prompt
return F.dialogue(lines(S.decodeText(M.currentPage() or '',M._revealed)),
lines(S.decodeText(M.currentPage() or '')),waiting,
M._arrowTicks or 0)
end
function F.choices(options,cursor,cols,opts)
if not options or #options==0 then return false end
return V.Gen3Overlay.paint(function(w,h)
local S=V.Gen3Screens;local g=love.graphics;local ctx=F.context(w,h);local u=ctx.scale()
if opts and opts.opaque then
ctx.setUIColor=function(role,r,gg,b,a) g.setColor(r,gg,b,role=='surface' and 1 or a) end
end
cols=math.max(1,cols or 1)
local f=S.font(19*u);local cw=180*u;local rows=math.ceil(#options/cols)
for _,label in ipairs(options) do cw=math.max(cw,f:getWidth(S.decodeText(label))+46*u) end
cw=math.min(cw,(w-48*u)/cols)
local rowH=32*u;local height=math.min(h*.65,rows*rowH+24*u)
local visible=math.max(1,math.floor((height-24*u)/rowH))
local selectedRow=math.floor(((cursor or 1)-1)/cols)
local first=math.max(0,selectedRow-visible+1)
local dialog=V.Gen3Overlay.dialogueRect
local width=cw*cols;local x=(dialog and dialog.x+dialog.w or w-24*u)-width
x=clamp(x,24*u,w-width-24*u)
local y=math.max(20*u,(dialog and dialog.y or h-24*u)-height-14*u)
V.UIPresentation.consolePanel(ctx,x,y,width,height,u)
for i,label in ipairs(options) do
local row=math.floor((i-1)/cols)-first;local col=(i-1)%cols
if row>=0 and row<visible then
local xx,yy=x+col*cw+16*u,y+12*u+row*rowH
if i==cursor then S.select(xx,yy,cw-32*u,rowH,u) end
S.text(S.decodeText(label),xx+18*u,yy,cw-52*u,rowH,19*u)
end
end
if first>0 or first+visible<rows then
S.text((selectedRow+1)..' / '..rows,x,y+height-13*u,width-14*u,12*u,10*u,nil,'right')
end
g.setColor(1,1,1,1)
end)
end
function F.banner(P)
local rs=P.Rs;local rse=P.Rse;local name,alpha
if rs and rs.task and rs.window then
name=rs.window.name;alpha=1-(rs.task.yOffset or 0)/(rs.OFFSCREEN_Y or 32)
elseif rse and rse.task and rse.window then
name=rse.window.name;alpha=1-(rse.task.yOffset or 0)/(rse.OFFSCREEN_Y or 40)
elseif P._state~=0 and (P._tPos or 0)>0 then
name=P._name;alpha=P._tPos/24
end
if not name or not alpha or alpha<=0 then return true end
name=V.Gen3Screens.decodeText(name)
return V.Gen3Overlay.paint(function(w,h)
local ctx=F.context(w,h);local draw=ctx.text
ctx.text=function(value,x,y,size,...) return draw(value,x,y,size*ctx.textScale(),...) end
V.UIPresentation.locationBanner(ctx,name,alpha)
end)
end
local function printerPage(p)
local full={};for i,row in ipairs(p.lines or {''}) do full[i]=row end
if p.active and (p.state=='char' or p.state=='pause') then
for i=p.pos,#p.toks do
local tok=p.toks[i]
if tok.t=='para' or tok.t=='scroll' or tok.t=='wait' then break end
if tok.t=='nl' then full[#full+1]=''
elseif tok.t=='c' then full[#full]=full[#full]..tok.s end
end
end
local shown={};for i,row in ipairs(p.lines or {''}) do shown[i]=V.Gen3Screens.decodeText(row) end
for i,row in ipairs(full) do full[i]=V.Gen3Screens.decodeText(row) end
return shown,full
end
function F.printerDialogue(p,frame)
if not p then return false end
local shown,full=printerPage(p)
local waiting=p.arrowFrame~=nil or p.state=='clear' or p.state=='scroll_start'
or p.state=='wait' or not p.active
return F.dialogue(shown,full,waiting,frame)
end
function F.callDialogue(s)
if not s or s.state<2 or not V.Gen3Overlay.available() then return false end
local shown,full,waiting={''},s.__colosseumCallPage or {''},false
if s.printer then
shown,full=printerPage(s.printer)


s.__colosseumCallPage=full
local p=s.printer
waiting=p.arrowFrame~=nil or p.state=='clear' or p.state=='scroll_start'
or p.state=='wait' or (s.state==6 and not p.active)
end
return F.dialogue(shown,full,waiting,s.frames or 0,
{slide=clamp((s.offset or 0)/32,0,1)})
end
local function revealedText(value,count)
local out={};local n=0
for ch in tostring(value or ''):gmatch('[%z\1-\127\194-\244][\128-\191]*') do
if n>=(count or math.huge) then break end
out[#out+1]=ch;n=n+1
end
return table.concat(out)
end
function F.oakDialogue(scene)
local printer=scene.printer
if not printer then return false end
local full=printer.pages and printer.pages[printer.page] or ''
local shown=revealedText(full,printer.revealed)
return V.Gen3Overlay.paint(function(w,h)
local S=V.Gen3Screens;local g=love.graphics
local rect=S.battleDialogueLayout(w,h,full)
S.panel(rect.x,rect.y,rect.w,rect.h,rect.u)
g.setFont(rect.font);g.setColor(.94,.94,.85,1)
g.setScissor(rect.x+rect.inset,rect.y+8*rect.u,
rect.contentW,rect.h-16*rect.u)
g.printf(shown,rect.x+rect.inset,rect.y+20*rect.u,rect.contentW,'left')
g.setScissor()
if printer.state=='clear' and printer.arrowFrame then
local x=rect.x+rect.w-31*rect.u;local y=rect.y+rect.h-27*rect.u
g.setColor(.9,.23,.13,1)
g.polygon('fill',x,y,x+12*rect.u,y,x+6*rect.u,y+8*rect.u)
end
local slot=scene.pal and scene.pal.slots and scene.pal.slots[15]
if slot and (slot.y or 0)>0 then
local c=slot.color or {0,0,0}
g.setColor((c[1] or 0)/31,(c[2] or 0)/31,(c[3] or 0)/31,
math.min(1,(slot.y or 0)/16))
g.rectangle('fill',rect.x,rect.y,rect.w,rect.h)
end
g.setColor(1,1,1,1)
end)
end
function F.install()
if F.installed then return end
local O=V.Gen3Overlay;O.install()
local M=req('src.ui.game3.message');local nativeDraw,nativeText=M.draw,M.drawText
local function replaced()
if not M.open then return false end
local S=V.Gen3Screens
if S.ownsBattleMessage and S.ownsBattleMessage(M) then return true end
if M._frame=='braille' then return false end
return F.message(M)
end
M.draw=function(...) if not replaced() then return nativeDraw(...) end end
M.drawText=function(...) if not replaced() then return nativeText(...) end end
local C=req('src.ui.game3.choice');local nativeChoice=C.draw
C.draw=function(...)
if C.active and F.choices(C.options,C.cursor,C.cols) then return end
return nativeChoice(...)
end
local P=req('src.ui.game3.map_name_popup');local popup=P.draw
P.draw=function(...) if not O.available() or not F.banner(P) then return popup(...) end end



local okCall,Call=pcall(req,'src.ui.game3.rse.pokenav.call_window')
if okCall then
local nativeCall=Call.draw
Call.draw=function(s,...)
if not F.callDialogue(s) then return nativeCall(s,...) end
end
end
local ok,Kit=pcall(req,'src.ui.game3.rse.scene_kit')
local okB,Birch=pcall(req,'src.ui.game3.rse.birch_speech')
if ok and okB then
local drawBirch,frame,fade=Birch.draw,Kit.birchDialogueFrame,Kit.drawFade
Kit.birchDialogueFrame=function(...)
local b=F.birch
if not b then return frame(...) end
if b.printer then
local shown,full=printerPage(b.printer)
F.dialogue(shown,full,b.printer.arrowFrame~=nil,b.frames or 0)
end
end
Kit.drawFade=function(...)
if F.birch and not F.choicesDrawn then
F.choicesDrawn=true
local RomText=req('src.core.game3.rom_text')
if F.gender then F.choices({RomText.plain('gText_BirchBoy'),RomText.plain('gText_BirchGirl')},F.gender.cursor+1) end
if F.yesNo then F.choices(lines(RomText.plain('gText_YesNo')),F.yesNo.cursor+1) end
end
return fade(...)
end
Birch.draw=function(self,...)
if self.naming or not O.available() then return drawBirch(self,...) end
F.birch=self;F.gender=self.genderMenu;F.yesNo=self.yesNo;F.choicesDrawn=false
self.genderMenu=nil;self.yesNo=nil
local printer=self.printer;local draw=printer and printer.draw
if printer then printer.draw=function() end end
local result={pcall(drawBirch,self,...)}
if printer then printer.draw=draw end
self.genderMenu=F.gender;self.yesNo=F.yesNo
F.birch=nil;F.gender=nil;F.yesNo=nil
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
end
local okRs,RsBirch=pcall(req,'src.ui.game3.rs.birch_speech')
if okRs then
local nativeRsDraw=RsBirch.draw
RsBirch.draw=function(self,...)
if self.naming or not O.available() then return nativeRsDraw(self,...) end
local dialogue,gender,names,yesNo=self.showDialogue,self.genderMenu,self.nameMenu,self.yesNo
self.showDialogue=false;self.genderMenu=nil;self.nameMenu=nil;self.yesNo=nil
local result={pcall(nativeRsDraw,self,...)}
self.showDialogue=dialogue;self.genderMenu=gender;self.nameMenu=names;self.yesNo=yesNo
if not result[1] then error(result[2],0) end
if dialogue and self.printer then
local shown,full=printerPage(self.printer)
F.dialogue(shown,full,self.printer.arrowFrame~=nil,self.frames or 0)
end
local T=req('src.core.game3.rom_text')
if gender then F.choices({T.plain('gBirchText_Boy'),T.plain('gBirchText_Girl')},gender.cursor+1)
elseif names then F.choices(self:presetNames(),names.cursor+1)
elseif yesNo then F.choices({T.at('gMenuYesNoItems',0),T.at('gMenuYesNoItems',1)},yesNo.cursor+1) end
return unpack(result,2)
end
end



local okOak,Oak=pcall(req,'src.ui.game3.new_game_scene')
if okOak and Oak then
local nativeOakDraw=Oak.draw
Oak.draw=function(self,...)
local nativeDialog=self.win and self.win.dialog
local dialogue=nativeDialog and self.printer
and not self.naming and O.available()
if not dialogue then return nativeOakDraw(self,...) end
self.win.dialog=nil
local result={pcall(nativeOakDraw,self,...)}
self.win.dialog=nativeDialog
if not result[1] then error(result[2],0) end
F.oakDialogue(self)
return unpack(result,2)
end
end
F.installed=true
end
return F
