

local V=...
local req=V.engineRequire or require
local S={wrapped=setmetatable({},{__mode='k'}),models={}}
function S.rse(session)
local P=req('src.core.game3.profile')
if P.family then return P.family(session)=='rse' end
local GV=req('src.core.GameVersion');return GV.layout and GV.layout(GV.get())=='rse' or false
end
S.ink={.94,.94,.85,1};S.muted={.68,.73,.7,1};S.accent={.96,.79,.28,1}
function S.canvas(w,h)
local k=math.min(w/268,h/192)
local c={k=k,x=(w-240*k)/2,y=(h-160*k)/2}
function c.panel(x,y,cw,ch,selected)
V.Gen3Screens.panel(c.x+x*k,c.y+y*k,cw*k,ch*k,k*.24)
if selected then
love.graphics.setColor(.92,.73,.22,.16)
love.graphics.rectangle('fill',c.x+(x+1)*k,c.y+(y+1)*k,(cw-2)*k,(ch-2)*k,2*k)
love.graphics.setColor(S.accent);love.graphics.rectangle('fill',c.x+(x+1)*k,c.y+(y+3)*k,k,(ch-6)*k)
end
end
function c.text(value,x,y,cw,ch,size,color,align)
value=V.Gen3Screens.decodeText(tostring(value or ''))
local pxSize=(size or 5)*k;local f,lines
repeat
f=V.Gen3Screens.font(pxSize);local _;_,lines=f:getWrap(value,math.max(1,cw*k))
if #lines*f:getHeight()<=ch*k or pxSize<=8 then break end
pxSize=pxSize-1
until false
local G=love.graphics;G.setFont(f)
local px,py=math.floor(c.x+x*k),math.floor(c.y+y*k+math.max(0,(ch*k-#lines*f:getHeight())/2))
G.setColor(0,0,0,.75);G.printf(value,px+1,py+1,cw*k,align or 'left')
G.setColor(color or S.ink);G.printf(value,px,py,cw*k,align or 'left')
end
function c.image(img,x,y,cw,ch,quad)
if not img then return end
local iw,ih=img:getDimensions();if quad then local _,_,qw,qh=quad:getViewport();iw,ih=qw,qh end
local scale=math.min(cw*k/iw,ch*k/ih)
love.graphics.setColor(1,1,1,1)
local px,py=c.x+(x+cw/2)*k-iw*scale/2,c.y+(y+ch/2)*k-ih*scale/2
if quad then love.graphics.draw(img,quad,px,py,0,scale,scale) else love.graphics.draw(img,px,py,0,scale,scale) end
end
function c.portrait(mon,x,y,cw,ch)
if not mon then return end
if req('src.core.game3.pokemon').isEgg(mon) then c.text('EGG',x,y+ch*.35,cw,ch*.4,4,S.muted,'center');return end
local size=math.min(cw,ch)*k
local ok=V.Gen3Screens.drawPortrait(mon,c.x+(x+cw/2)*k-size/2,c.y+(y+ch/2)*k-size/2,size)
if not ok then local pic=req('src.core.game3.pokemon').monFrontPic(mon);if pic then c.image(pic.image,x,y,cw,ch) end end
end
function c.model(mon,x,y,cw,ch,owner)
if not mon or req('src.core.game3.pokemon').isEgg(mon) or V.Gen3Runtime.prefs().menuModels==false then return c.portrait(mon,x,y,cw,ch) end
local U=V.Gen3UI;local prev=U.modelViewport
U.modelViewport={c.x+x*k,c.y+y*k,cw*k,ch*k,noFrame=true}
U.drawModel(mon,0,0,0,0);U.viewer.owner=owner;c.modelOwner=owner
U.modelViewport=prev
end
function c.header(title,detail)
c.panel(0,-13,240,17);c.text(title,6,-9,148,10,6)
c.text(detail or '',157,-8,77,9,4,S.muted,'right')
end
function c.footer(value)
c.panel(0,151,240,13)
local controls=c.modelOwner and V.Gen3UI.modelControls(c.modelOwner)
if controls then
c.text(value,6,152,228,5,3.5,S.muted)
c.text(controls,6,158,228,5,3.2,S.muted)
else c.text(value,6,154,228,7,3.7,S.muted) end
c.footerControls=controls
end
function c.rows(rows,cursor,x,y,cw,rh,first,count)
first=first or 1;count=count or #rows
for i=first,math.min(#rows,first+count-1) do
local yy=y+(i-first)*rh;c.panel(x,yy,cw,rh-1,i==cursor)
local row=rows[i];c.text(type(row)=='table' and row.label or row,x+5,yy+2,cw-10,rh-4,5,i==cursor and S.accent or S.ink)
end
end
return c
end
function S.mon(species,dex)
local D=req('src.core.game3.dex')
local personality=dex and D.defaultPersonality(dex,species) or 0
local key=tostring(species)..':'..tostring(personality)
if not S.models[key] then S.models[key]={species=species,speciesNumbering='internal',personality=personality,isShiny=false} end
return S.models[key]
end
function S.alive(owner)
for _,layer in ipairs(req('src.ui.game3.stack').drawOrder()) do if layer.mod==owner then return true end end
return false
end


function S.capture(draw,...)
local F=req('src.ui.game3.frlg_font');local C=req('src.ui.game3.chrome');local W=req('src.ui.game3.window')
local events,undo={},{}
local function hook(t,key,fn)
local old=t[key];if type(old)~='function' then return end
undo[#undo+1]=function() t[key]=old end;t[key]=function(...) fn(...);return old(...) end
end
local inside=false
local old=F.draw
F.draw=function(value,x,y,opts)
if not inside then events[#events+1]={kind='text',value=value,x=x,y=y,opts=opts or {}} end
local was=inside;inside=true;local result={pcall(old,value,x,y,opts)};inside=was
if not result[1] then error(result[2],0) end;return unpack(result,2)
end
undo[#undo+1]=function() F.draw=old end
local function frame(tx,ty,tw,th) events[#events+1]={kind='panel',x=tx*8-3,y=ty*8-3,w=tw*8+6,h=th*8+6} end
hook(C,'stdFrame',frame);hook(C,'fixedStdFrame',frame);hook(C,'userFrame',function(_,...) frame(...) end)
hook(C,'dialogueFrame',function() local x,y,w,h=2,15,26,4;if C.dialogueWindow then x,y,w,h=C.dialogueWindow() end;frame(x-1,y-1,w+2,h+2) end)
hook(W,'cursorPx',function(x,y) events[#events+1]={kind='cursor',x=x,y=y} end)
hook(F,'drawGlyph',function(id,x,y) if not inside and id==239 then events[#events+1]={kind='cursor',x=x,y=y} end end)
for _,path in ipairs({'src.ui.game3.bag_chrome','src.ui.game3.rse.bag_chrome'}) do
local ok,B=pcall(req,path)
if ok and type(B.drawItemIcon)=='function' then
local draw=B.drawItemIcon
hook(B,'drawItemIcon',function(id,x,y) events[#events+1]={kind='item',id=id,x=x,y=y,draw=draw} end)
end
end
local result={pcall(V.Gen3Menus.nativePass,draw,...)}
for i=#undo,1,-1 do undo[i]() end
if not result[1] then error(result[2],0) end
return events
end
function S.replay(c,events,filter)
for _,e in ipairs(events) do if not filter or filter(e) then
if e.kind=='panel' then c.panel(e.x,e.y,e.w,e.h)
elseif e.kind=='cursor' then c.text('>',e.x,e.y,7,10,6,S.accent)
elseif e.kind=='item' then
local G=love.graphics;G.push('all');G.translate(c.x,c.y);G.scale(c.k,c.k);e.draw(e.id,e.x,e.y);G.pop()
elseif e.kind=='text' then
local opts=e.opts or {};local value=V.Gen3Screens.decodeText(e.value)
if opts.limitChars then

local chars={};for char in value:gmatch('[%z\1-\127\194-\244][\128-\191]*') do chars[#chars+1]=char end
value=table.concat(chars,'',1,math.min(#chars,opts.limitChars))
end
local pitch=opts.linePitch or (opts.small and 12 or 16);local n=0
for line in (value..'\n'):gmatch('(.-)\n') do
c.text(line,e.x,e.y+n*pitch,math.min(opts.maxWidth or 240,240-e.x),pitch,opts.small and 5 or 6);n=n+1
end
end
end end
end
function S.wrap(N,title,render,owner)
if not N or type(N.draw)~='function' or S.wrapped[N] then return end
local original=N.draw;owner=owner or N;S.wrapped[N]=original
V.Gen3MenuScene.register(owner)
N.draw=function(...)
if not S.alive(owner) or not V.Gen3Overlay.available() then return original(...) end
local events=S.capture(original,...);local args={...}
return V.Gen3Overlay.paint(function(w,h)
local c=S.canvas(w,h);c.header(title)
if render then render(c,N,events,unpack(args)) else
if title~='PC / STORAGE' and title~='SAVE GAME' and not (title=='POKé MART' and N.mode=='root') then c.panel(0,5,240,144) end
S.replay(c,events)
end
S.lastDraw={module=N,title=title,events=#events}
end)
end
end
function S.itemPc(c,N,events)
local items=req('src.core.game3.storage').ensure(N._session).items
local I=req('src.core.game3.items_data');local idx=(N.scroll or 0)+(N.row or 0)+1
local selected=items[idx];local mode=N.state or N.mode
c.panel(0,7,91,141);c.text(N._toss and 'TOSS ITEMS' or 'WITHDRAW ITEMS',6,12,79,13,5,S.accent)
local icon;for _,e in ipairs(events) do if e.kind=='item' then icon=e;break end end
if icon then local G=love.graphics;G.push('all');G.translate(c.x+26*c.k,c.y+32*c.k);G.scale(c.k*1.25,c.k*1.25);icon.draw(icon.id,0,0);G.pop() end
local description=selected and I.description(selected.id) or 'Return to the PC.'
c.text(tostring(description):gsub('\n',' '),7,85,77,53,5,S.muted)
local rows={};for i,e in ipairs(items) do rows[i]=I.displayName(e.id)..'  × '..e.qty
if (mode=='move' and N.moveOrig==i-1) or (mode=='swap' and N.swapFrom==i-1) then rows[i]='> '..rows[i] end
end;rows[#rows+1]='CANCEL'
local count=S.rse(N._session) and 8 or 6
c.rows(rows,idx,97,7,143,17,(N.scroll or 0)+1,count)
c.footer((mode=='move' or mode=='swap') and 'A PLACE ITEM   B CANCEL MOVE' or 'A SELECT   B BACK   SELECT MOVE ITEM')
if mode=='submenu' then c.panel(128,92,111,55);c.rows({'WITHDRAW','GIVE','CANCEL'},N.subCursor,132,96,103,15)
elseif mode=='qty' or mode=='quantity' then
c.panel(98,108,141,39);c.text('QUANTITY   × '..(N.quantity or N.qty or 1),104,112,129,15,6,S.accent);c.text('↑ / ↓ ADJUST   A CONFIRM   B CANCEL',104,132,129,10,3.8)
elseif mode=='yesno' then c.panel(151,80,85,38);c.rows({'YES','NO'},N.yesCursor,155,84,77,15)
end
if mode~='list' and mode~='submenu' and mode~='qty' and mode~='quantity' then
local msg=N._message or N.resultText or N.msgText
if msg then c.panel(0,115,145,33);c.text(tostring(msg):gsub('\n',' '),6,119,133,25,4.6) end
end
end
function S.shop(c,N,events)
if N.mode=='sell' then return end
local state=N.state or N.mode
if N.mode=='root' then
local rows={};for _,e in ipairs(events) do if e.kind=='text' and e.y<100 then rows[#rows+1]=e.value end end
c.rows(rows,N.cursor,0,7,91,18)
c.panel(0,115,240,33);c.text(tostring(N._status or ''):gsub('\n',' '),7,120,226,23,5)
c.footer('↑ / ↓ SELECT   A CONFIRM   B BACK');return
end
c.panel(0,7,91,141);c.text('MONEY',6,13,79,10,4.5,S.muted)
c.text(tostring(N._session.money or 0),6,25,79,15,7,S.accent)
local icon;local rows,byY={},{}
local nameX=N._rse and 120 or 96
for _,e in ipairs(events) do
if e.kind=='item' then icon=e end
if e.kind=='text' and e.x==nameX and e.y>=8 and e.y<133 then

local row=byY[e.y];if not row then row={y=e.y};byY[e.y]=row;rows[#rows+1]=row end
row.name=e.value
end
end
for _,e in ipairs(events) do if e.kind=='text' and e.x>150 and byY[e.y] then byY[e.y].price=e.value end end
table.sort(rows,function(a,b) return a.y<b.y end)
if icon then local G=love.graphics;G.push('all');G.translate(c.x+27*c.k,c.y+47*c.k);G.scale(c.k*1.2,c.k*1.2);icon.draw(icon.id,0,0);G.pop() end
local visible=0;local selected=N._rse and (N.row or 0)+1 or (N.cursor or 1)-(N.scroll or 0)
for _,row in ipairs(rows) do if row.name then
visible=visible+1;local y=7+(visible-1)*13;c.panel(97,y,143,12,visible==selected)
c.text(row.name,102,y+1,92,10,5);c.text(row.price or '',197,y+1,37,10,5,S.muted,'right')
end end
local message=N._status
if not message then
local desc={};for _,e in ipairs(events) do if e.kind=='text' and e.y>=104 and e.x<96 then desc[#desc+1]=V.Gen3Screens.decodeText(e.value) end end
c.text(table.concat(desc,' '):gsub('\n',' '),7,92,77,48,4.6,S.muted)
end
if state=='qty' or state=='buy_qty' then
c.panel(98,110,141,36);c.text('QUANTITY  × '..tostring(N.qty),104,115,100,12,5,S.accent)
local cost=N._totalCost or (N._pending and N._pending.price or 0)*(N.qty or 1)
c.text(tostring(cost),183,132,50,9,4.5,S.ink,'right')
elseif state=='confirm' or state=='buy_confirm' then
c.panel(153,109,86,38);c.rows({'YES','NO'},N.yesCursor or N.yesNoCursor,157,113,78,15)
end
if message then c.panel(0,105,94,43);c.text(tostring(message):gsub('\n',' '),6,110,82,33,4.5) end
c.footer('A CONFIRM   B BACK   D-PAD SELECT / CHANGE QUANTITY')
end
function S.relearner(c,N)
local P=req('src.core.game3.pokemon');local moves=N.moves();local rows={}
for i,id in ipairs(moves) do rows[i]=P.moveName(id) end;rows[#rows+1]='CANCEL'
c.panel(0,7,106,105);c.rows(rows,N.cursor,111,7,129,15,(N.scroll or 0)+1,7)
local id=moves[N.cursor]
if id then
local row=P.battleMove(id) or {}
local types={'NORMAL','FIGHTING','FLYING','POISON','GROUND','ROCK','BUG','GHOST','STEEL','???','FIRE','WATER','GRASS','ELECTRIC','PSYCHIC','ICE','DRAGON','DARK'}
c.text(type(row.type)=='number' and types[row.type+1] or tostring(row.type or 'NORMAL'):upper(),6,12,94,12,5,S.accent)
c.text('POWER '..((row.power or 0)>1 and row.power or '---')..'    PP '..tostring(row.pp or 0),6,29,94,12,4.5)
c.text('ACCURACY '..((row.accuracy or 0)>0 and row.accuracy or '---'),6,43,94,12,4.5)
local desc=req('src.core.game3.summary_data').moveDescription(id,P.moveName(id))
c.text(tostring(desc or ''):gsub('\n',' '),6,64,94,40,5,S.muted)
end
c.panel(0,116,240,32);c.text(tostring(N.prompt or ''):gsub('\n',' '),7,121,226,22,5.5)
if N.state=='yesno' then c.panel(173,63,67,40);c.rows({'YES','NO'},N.yesNoCursor,177,67,59,16) end
c.footer('↑ / ↓ SELECT MOVE   A CONFIRM   B BACK')
end
function S.install()
if S.installed then return end
for _,row in ipairs({
{'pc_menu','PC / STORAGE'},{'item_pc','ITEM STORAGE'},{'rse.item_storage','ITEM STORAGE'},
{'save_menu','SAVE GAME'},{'shop_menu','POKé MART'},{'rse.shop_menu','POKé MART'},
{'move_relearner','MOVE REMINDER'},{'rse.move_relearner','MOVE REMINDER'},
{'rse.mailbox','MAILBOX'},{'rse.mail','MAIL'},
}) do local ok,N=pcall(req,'src.ui.game3.'..row[1]);if ok then
local render=(row[1]=='item_pc' or row[1]=='rse.item_storage') and S.itemPc or row[1]=='shop_menu' and S.shop
or (row[1]=='move_relearner' or row[1]=='rse.move_relearner') and S.relearner or nil
S.wrap(N,row[2],render)
end end


local PC=req('src.ui.game3.pc_menu')
for _,key in ipairs({'show','handleInput','draw'}) do
local original=PC[key]
PC[key]=function(...)
local args={...};local session=(key=='show' and args[1] and args[1].session) or PC._session
if not S.rse(session) then return original(...) end
local R=req('src.core.game3.rom_text');local added={}
for from,to in pairs({Text_AccessWhichPC='gText_WhichPCShouldBeAccessed',gText_WhatWouldYouLikeToDo='gText_WhatWouldYouLike'}) do
if not R.has(from) and R.overrides[from]==nil and R.has(to) then R.overrides[from]=R.ir(to);added[#added+1]=from end
end
local result={pcall(original,...)};for _,from in ipairs(added) do R.overrides[from]=nil end
if not result[1] then error(result[2],0) end;return unpack(result,2)
end
end


local Sell=req('src.ui.game3.sell_flow')
for _,key in ipairs({'start','handleInput','draw'}) do
local original=Sell[key]
Sell[key]=function(first,...)
if not S.rse(first and first.session) then return original(first,...) end
local R=req('src.core.game3.rom_text');local added={}
for from,row in pairs({
gText_TimesStrVar1={'gText_TimesVar1',{}},
gText_OhNoICantBuyThat={'gText_CantBuyKeyItem',{[2]=1}},
gText_HowManyWouldYouLikeToSell={'gText_HowManyToSell',{[2]=1}},
gText_ICanPayThisMuch_WouldThatBeOkay={'gText_ICanPayVar1',{[1]=3}},
gText_TurnedOverItemsWorthYen={'gText_TurnedOverVar1ForVar2',{[2]=1,[1]=3}},
}) do
if not R.has(from) and R.has(row[1]) then
local copy={};for i,token in ipairs(R.ir(row[1])) do
local t={};for k,v in pairs(token) do t[k]=v end
if t.t=='strvar' then t.n=row[2][t.n] or t.n end;copy[i]=t
end
R.overrides[from]=copy;added[#added+1]=from
end
end


local Q=req('src.core.game3.quest_log_recorder');local location,event=Q.location,Q.event
Q.location=function() return '' end;Q.event=function() end
local result={pcall(original,first,...)}
Q.location,Q.event=location,event
for _,from in ipairs(added) do R.overrides[from]=nil end
if not result[1] then error(result[2],0) end;return unpack(result,2)
end
end
S.installed=true
end
return S
