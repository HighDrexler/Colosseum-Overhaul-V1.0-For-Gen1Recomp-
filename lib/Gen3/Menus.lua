
local V=...
local req=V.engineRequire or require
local M={}
local function g() return love.graphics end
local function text(s) return V.Gen3Screens.decodeText(tostring(s or '')) end
local function clamp(n,a,b) return math.max(a,math.min(b,n)) end
local function label(action) return tostring(action or ''):gsub('_',' ') end
local function status(mon)
if mon.isEgg then return nil end
if (mon.hp or 0)<=0 then return 'FNT' end
local v=mon.native and mon.native.status or mon.status
if type(v)=='string' then return v~='' and v~='NONE' and v or nil end
v=tonumber(v) or 0
if v%8>0 then return 'SLP' elseif math.floor(v/8)%2==1 or math.floor(v/128)%2==1 then return 'PSN'
elseif math.floor(v/16)%2==1 then return 'BRN' elseif math.floor(v/32)%2==1 then return 'FRZ'
elseif math.floor(v/64)%2==1 then return 'PAR' end
end
function M.context(w,h)
local G=g();local sc=math.max(.1,math.floor(math.min(w/160,h/144)))
if math.min(w/160,h/144)<1 then sc=math.min(w/160,h/144) end
local ox,oy=math.floor((w-160*sc)/2+.5),math.floor((h-144*sc)/2+.5)
local ctx={state={},partyMenu={},dexUI={optionDisplay=function(row) return row.value or '' end},textScale=1.08,partyActionMaxHeight=116}
ctx.graphics=setmetatable({getDimensions=function() return w,h end,getWidth=function() return w end,
getHeight=function() return h end},{__index=G})
ctx.finalCanvas=function() return ox,oy,sc end;ctx.partyCanvas=ctx.finalCanvas
ctx.setPartyTransform=function(x,y,s) ox,oy,sc=x,y,s end
ctx.roundedRect=function(mode,x,y,cw,ch,r) G.rectangle(mode,x,y,cw,ch,r,r) end
ctx.font=function(size)
if size>=7 then return V.Gen3Screens.font(size) end


local f=V.Gen3Screens.font(size*sc)
return {getHeight=function() return f:getHeight()/sc end,
getWidth=function(_,s) return f:getWidth(s)/sc end,
getWrap=function(_,s,width) local len,rows=f:getWrap(s,width*sc);return len/sc,rows end}
end
ctx.finalText=function(value,x,y,size,color,xx,yy,s,align,width)
value=text(value);local f=V.Gen3Screens.font(math.max(4,math.floor(size*s+.5))*1.08)
G.push('all');G.origin();G.setFont(f)
local px,py=math.floor(xx+x*s+.5),math.floor(yy+y*s+.5)
G.setColor(0,0,0,(color[4] or 1)*.753)
if width then G.printf(value,px+1,py+1,width*s,align or 'left') else G.print(value,px+1,py+1) end
G.setColor(color)
if width then G.printf(value,px,py,width*s,align or 'left') else G.print(value,px,py) end
G.pop()
end
ctx.finalTextWidth=function(value,size,s) return V.Gen3Screens.font(math.max(4,math.floor(size*s+.5))*1.08):getWidth(text(value))/s end
ctx.finalTextFitted=function(value,x,y,size,minSize,color,xx,yy,s,align,width,height)
while size>minSize do
local f=V.Gen3Screens.font(math.max(4,math.floor(size*s+.5))*1.08)
if f:getWidth(text(value))<=width*s and f:getHeight()<=height*s then break end
size=size-.1
end
ctx.finalText(value,x,y,size,color,xx,yy,s,align,width)
end
ctx.partyText=function(value,x,y,size,color,align,width) ctx.finalText(value,x,y,size,color,ox,oy,sc,align,width) end
ctx.partyTextWidth=function(value,size) return ctx.finalTextWidth(value,size,sc) end
ctx.itemTargetIsStone=function() return false end;ctx.status=status
ctx.stat=function(mon,...) for _,k in ipairs({...}) do if mon.stats[k] then return mon.stats[k] end end;return '-' end
ctx.moveName=function(_,move) return move and move.name or '---' end
ctx.movePP=function(_,move) return move and (move.pp..'/'..move.maxPP) or '' end
ctx.hpBar=function(x,y,width,mon)
local ratio=clamp((mon.hp or 0)/math.max(1,mon.maxHp or 1),0,1)
G.setColor(.1,.1,.09,1);ctx.roundedRect('fill',x,y,width,4,1.5)
G.setColor(.78,.76,.63,1);ctx.roundedRect('fill',x+1,y+1,width-2,2,1)
if ratio>0 then
G.setColor(ratio<.2 and {.9,.18,.14,1} or ratio<.5 and {.96,.72,.15,1} or {.22,.84,.36,1})
ctx.roundedRect('fill',x+1,y+1,math.max(1,(width-2)*ratio),2,1)
end
end
local compat={generation='gen2',setUIColor=function(_,...) G.setColor(...) end,
userTextScale=function() return 1 end,humanizeIdentifier=label,
cleanItemDescription=function(s) return text(s):gsub('\n',' ') end}
compat.panelText=ctx.partyText
compat.drawColosseumPortrait=function(_,mon,x,y,cw,ch)
if mon.isEgg then
ctx.partyText('EGG',x,y+ch*.38,2.4,{.9,.9,.8,1},'center',cw);return true
end
local px,py=G.transformPoint(x,y);local ex,ey=G.transformPoint(x+cw,y+ch)
G.push('all');G.origin()
local drawn=V.Gen3Screens.drawPortrait(mon.native,px,py,math.min(ex-px,ey-py))
if not drawn then
local pic=req('src.core.game3.pokemon').monFrontPic(mon.native)
if pic and pic.image then G.setColor(1,1,1,1);G.draw(pic.image,px,py,0,(ex-px)/pic.image:getWidth(),(ey-py)/pic.image:getHeight()) end
end
G.pop();return true
end
compat.genderSymbol=function(mon)
if mon.isEgg then return nil end
local value=req('src.core.game3.pokemon').gender(mon.species,mon.native.personality or 0)
return value=='M' and '♂' or value=='F' and '♀' or nil
end
compat.drawGenderIcon=function(x,y,size,value)
G.push('all');G.origin();V.Gen3Screens.text(value,x,y,size*1.2,size*1.2,size,
value=='♂' and {.35,.65,1,1} or {1,.46,.58,1});G.pop()
end
compat.drawPartyExpBar=function(_,mon,x,y,width)
local ratio=mon.expRatio or 0
G.setColor(.10,.18,.24,1);ctx.roundedRect('fill',x,y,width,4,1.5)
G.setColor(.14,.28,.38,1);ctx.roundedRect('fill',x+1,y+1,width-2,2,1)
if ratio>0 then G.setColor(.08,.48,.96,1);ctx.roundedRect('fill',x+1,y+1,(width-2)*ratio,2,1) end
end
ctx.compat=compat;return ctx
end



function M.nativePass(draw,...)
local G=g()
M.scratch=M.scratch or G.newCanvas(240,160,{dpiscale=1})
G.push('all');G.setCanvas(M.scratch);G.origin();G.setScissor();G.clear(0,0,0,0)
local result={pcall(draw,...)};G.pop()
if not result[1] then error(result[2],0) end
end
local function paint(kind,draw)
return V.Gen3Overlay.paint(function(w,h)
local ctx=M.context(w,h);draw(V.MenuPresentation.bind(ctx),ctx,w,h)
end)
end
function M.start(N)
return paint('start',function(renderer,ctx,w,h)
local items={};for i,row in ipairs(N.ENTRIES or {}) do items[i]={label=text(row.label)} end
renderer.start({}, {items=items,index=N._confirmExit and 0 or N.cursor,
scroll=N._scrollOffset or 0,maxVisible=(N._data and N._data.maxVisible) or N.MAX_VISIBLE or 8})
local d=N._data;local extra=d and d.extraWindow and N._ctx and d.extraWindow(N._kind,N._ctx)
if extra then
local value=req('src.core.game3.rom_text').plain(extra.key,{stringVars=extra.vars})
V.Gen3Screens.panel(24,24,w*.3,80,1)
V.Gen3Screens.text(text(value):gsub('\n','  '),40,34,w*.3-32,60,22)
end
end)
end
function M.options(N)
local st=N._st
local pages=st and st.pages or N._pages
local page=pages and pages[#pages]
if not page then return false end
local nativeContext=st and st.ctx or N._ctx
local rows={};local RomText=req('src.core.game3.rom_text')
for i,row in ipairs(page.rows) do
local value='';local name=row.label or ''
if row.cart then
local c=row.cart;local current=tonumber(req('src.core.game3.options').block(nativeContext.options)[c.key]) or 0
name=RomText.plain(c.label)
value=c.frame and ('TYPE '..(current+1)) or RomText.plain(c.choices[current+1])
elseif row.value then
local ok,result=pcall(row.value,nativeContext);value=ok and tostring(result) or '—'
end
rows[i]={label=text(name),__gen3uiUIRow={value=text(value)}}
end
rows[#rows+1]={label='BACK'}
return paint('options',function(renderer)
renderer.start({}, {__gen3uiUISettings=true,title=text(page.title),items=rows,index=page.index,
scroll=page.scroll or 0,maxVisible=N.VISIBLE or 7,footer='LEFT / RIGHT: CHANGE   A: SELECT   B: BACK'})
end)
end
function M.generic(menu)
return paint('mod-menu',function(renderer,ctx,w,h)
local items={}
for i,row in ipairs(menu.rows) do
items[i]={label=text(type(row.label)=='function' and row.label() or row.label)}
end
local first=math.max(1,math.min(menu.cursor-3,#items-6))
renderer.start({}, {__gen3uiUISettings=true,title=menu.title,items=items,index=menu.cursor,
scroll=first-1,maxVisible=7,fullWidthRows=true,left=menu.extra and 4 or 28,width=menu.extra and 88 or 128,
footer=menu.extra and '' or menu.footer or 'A: SELECT   B: BACK   LEFT / RIGHT: PAGE'})
if menu.extra then
local x,y,s=ctx.finalCanvas()
V.Gen3UI.modelViewport={x+100*s,y+30*s,55*s,64*s}
local ok,err=pcall(menu.extra,menu)
V.Gen3UI.modelViewport=nil
if not ok then error(err,0) end
local U=V.Gen3UI;if U.viewer then U.viewer.owner=menu end
ctx.finalTextFitted(menu.footer or 'A: SELECT   B: BACK   LEFT / RIGHT: PAGE',7,134,1.85,1.65,{.70,.79,.77,1},x,y,s,'left',147,4)
local controls=U.modelControls(menu)
if controls then ctx.finalTextFitted(controls,7,139,1.8,1.5,{.70,.79,.77,1},x,y,s,'left',147,4) end
end
end)
end
function M.partyFacade(N)
local P=req('src.core.game3.pokemon');local Items=req('src.core.game3.items_data')
local data={pokemon={},items={},moves={}};local party={}
for i,native in ipairs(N._party or {}) do
local mon={native=native,species=native.species,nickname=P.displayMonName(native),level=native.level,
hp=native.hp,maxHp=native.maxHp,isEgg=P.isEgg(native),item=native.heldItem or native.item,
stats={hp=native.maxHp,attack=native.attack,defense=native.defense,speed=native.speed,
specialAttack=native.spAtk,specialDefense=native.spDef},moves={}}
if mon.item==0 or mon.item=='ITEM_NONE' or mon.item=='NONE' then mon.item=nil end
for j,entry in ipairs(N.movesFor(i)) do
local id=entry.id
if id and id~=0 then
local maxPP=(native.maxPp or {})[j] or P.movePp(id) or 0
mon.moves[j]={id=id,name=P.moveName(id),pp=entry.pp or maxPP,maxPP=maxPP}
end
end
local Growth=req('src.core.game3.battle.experience')
if Growth.expForLevel then
local a=Growth.expForLevel(native,native.level);local b=Growth.expForLevel(native,math.min(100,(native.level or 1)+1))
mon.expRatio=b>a and clamp(((native.exp or a)-a)/(b-a),0,1) or 0
end
if N._hpAnim and N._hpAnim.slot==i then mon.hp=N._hpAnim.current or mon.hp end
party[i]=mon;data.pokemon[mon.species]={name=P.name(mon.species)}
if mon.item and mon.item~=0 then data.items[mon.item]={name=Items.displayName(mon.item)} end
end
local mode=N.mode
local actions=mode=='action' and N.ACTIONS or mode=='item_action' and N.ITEM_ACTIONS
local submenu
if actions then submenu={index=mode=='action' and N.actionCursor or N.itemActionCursor,items={}}
for i,id in ipairs(actions) do submenu.items[i]={label=label(id)} end
end
local prompt=mode=='switch' and 'Move to where?' or mode=='use' and 'Use on which POKéMON?'
or mode=='give' and 'Give to which POKéMON?' or mode=='battle_faint' and 'Choose a replacement.'
or mode=='move_tutor' and 'Teach which POKéMON?' or 'Choose a POKéMON.'
local state={party=party,index=N.cursor,exitSelected=N.cursor>#party,submenu=submenu,
switchFrom=N.switchFrom,prompt=prompt,pokemon=data.pokemon,items=data.items,
hideFooter=mode=='message' or mode=='yesno' or mode=='forget' or mode=='stat_growth' or mode=='choose_multi',
exitLabel=(mode=='battle_faint' or N._previousMode=='battle_faint') and 'REQUIRED' or nil}
state.targetLabel=function(mon)
for i,row in ipairs(party) do if row==mon then
local value=N.slotDescription and N.slotDescription(i)
return value and text(value),{.78,.90,.76,1}
end end
end
return {data=data,save={party=party}},state
end
function M.party(N)
local game,state=M.partyFacade(N)
return paint('party',function(renderer,ctx)
renderer.party(game,state)
if N.mode=='choose_multi' then
local x,y,s=ctx.partyCanvas()
local S=V.Gen3Screens
S.panel(x+5*s,y+130*s,72*s,10*s,s*.22)
S.text(tostring(#N._chooseOrder)..' / '..N._chooseMax..' SELECTED',x+9*s,y+131*s,64*s,8*s,2.7*s)
for i,value in ipairs({'CONFIRM','CANCEL'}) do
local xx=x+(80+(i-1)*39)*s
S.panel(xx,y+130*s,36*s,10*s,s*.22)
if N.cursor==i+6 then S.select(xx+2*s,y+131*s,32*s,8*s,s*.25) end
S.text(value,xx+3*s,y+131*s,30*s,8*s,2.6*s,nil,'center')
end
end
end)
end
local pocketIds={ITEMS='ITEM',POKE_BALLS='BALL',KEY_ITEMS='KEY_ITEM',TM_CASE='TM_HM',TM_HM='TM_HM',BERRY_POUCH='BERRY',BERRIES='BERRY'}
function M.bagFacade(N,skin)
local Items=req('src.core.game3.items_data');local rows={};local native=N.list()
for i,row in ipairs(native) do
local important=(row.info and tonumber(row.info.importance) or 0)~=0
local name=text(row.name)
if Items.isTm(row.id) then
local P=req('src.core.game3.pokemon');local move=P.moveFromTmItem(row.id)
if move then name=name..'  '..P.moveName(move) end
end
if N._session and Items.toNumericId(N._session.registeredItem)==Items.toNumericId(row.id) then name='> '..name end
rows[i]={id=row.id,name=name,count=row.qty,showCount=not important and N.currentPocket()~='KEY_ITEMS'}
end
local ids={};for i,id in ipairs(Items.BAG_POCKET_ORDER) do ids[i]=pocketIds[id] or id end
local pocket=N.currentPocket();local selected=native[N.cursor]
local out={rows=rows,index=N.cursor,scroll=N.scroll or 0,visibleRows=skin and skin.MAX_SHOWN or 6,pocketIds=ids,
pocket=function() return {id=pocketIds[pocket] or pocket,label=Items.POCKET_LABEL[pocket] or label(pocket)} end,
description=function() return selected and selected.description or 'Close the bag.' end}
if N.mode=='action' and not skin then out.submenu={rows=N.ACTIONS,index=N.actionCursor} end
if N.mode=='toss' or N.mode=='deposit' then out.qtyState={qty=N.tossQty} end
if N.mode=='toss_confirm' then out.confirm={choice=N.yesNoCursor,prompt='TOSS THESE ITEMS?'} end
if N.mode=='message' then out.message={N.messageText or ''}
elseif N.mode=='deposit_done' then out.message={N._depositText or ''}
elseif N.mode=='toss_done' then out.message={'Discarded '..tostring(N.tossQty)..' '..(selected and selected.name or 'items')..'.'} end
return out
end
function M.bag(N,skin)
return paint('bag',function(renderer,ctx,w,h)
renderer.bag(M.bagFacade(N,skin),w,h,false)
if skin and N.mode=='action' then
local rs=N._rsBag
local grid=skin._st and skin._st.grid or rs and skin.grid(N,N.list()[N.cursor]);local rows={}
if grid then
for i=1,grid.cols*grid.rows do local cell=grid.cells[i]
local name=type(cell)=='table' and cell.name or cell
rows[i]=name and text((skin.ACTION_TEXT or {})[name] and req('src.core.game3.rom_text').plain(skin.ACTION_TEXT[name]) or label(name)) or ''
end
M.actionGrid={rows=rows,index=rs and rs.gridPos or skin._st.gridPos+1,cols=grid.cols}
end
end
end)
end
local gridModes={list=true,switch=true,use=true,give=true,choose=true,battle_switch=true,battle_faint=true,move_tutor=true,softboiled=true,choose_multi=true}
function M.gridIndex(index,count,dir,multi)
local exit=multi and 8 or 7
if index>count then
if multi and (dir=='left' or dir=='right') then return index==7 and 8 or 7 end
return dir=='up' and count or dir=='down' and 1 or index
end
if dir=='left' then return index%2==0 and index-1 or index end
if dir=='right' then return index%2==1 and index<count and index+1 or index end
if dir=='up' then return index>2 and index-2 or exit end
if dir=='down' then return index+2<=count and index+2 or exit end
return index
end
function M.install()
if M.installed then return end
local O=V.Gen3Overlay;O.install()
local Scene=V.Gen3MenuScene;Scene.install()
for _,path in ipairs({'src.ui.game3.option_menu','src.ui.game3.rse.option_menu','src.ui.game3.rs.option_menu'}) do
local ok,N=pcall(req,path)
if ok then
Scene.register(N)
local draw=N.draw
N.draw=function(...)
if not O.available() then return draw(...) end
M.nativePass(draw,...)
M.options(N)
end
end
end
local Start=req('src.ui.game3.start_menu');local sd=Start.draw
Scene.register(Start)
Start.draw=function(...)
if not Start.open or not O.available() then return sd(...) end
M.nativePass(sd,...);M.start(Start)
if Start._confirmExit then
V.Gen3FieldUI.dialogue({'Return to the main menu?'},{'Return to the main menu?'},false,0)
V.Gen3FieldUI.choices({'YES','NO'},Start._confirmCursor)
end
end
local Party=req('src.ui.game3.party_menu');local pd,pi=Party.draw,Party.handleInput
local nativePartyDraw=pd
pd=function(...)


local actions=Party.ACTIONS;local aliases={}
for i,label in ipairs(actions) do aliases[i]=label=='REMEMBER MOVES' and 'SUMMARY' or label end
Party.ACTIONS=aliases
local result={pcall(nativePartyDraw,...)};Party.ACTIONS=actions
if not result[1] then error(result[2],0) end
return unpack(result,2)
end
Scene.register(Party,function(N) return N.mode~='oak' and N.mode~='summary' end)
Party.draw=function(...)
if not Party.open or Party.mode=='summary' or req('src.ui.game3.summary_menu').isOpen()
or Party.mode=='oak' or not O.available() then return pd(...) end
M.nativePass(pd,...);M.party(Party)
if Party.mode=='message' or Party.mode=='yesno' then
local value=text(Party._messageText or Party._yesNoPrompt or '')
V.Gen3FieldUI.dialogue({value},{value},Party.mode=='message',0)
if Party.mode=='yesno' then V.Gen3FieldUI.choices({'YES','NO'},Party._yesNoCursor,1,{opaque=true}) end
elseif Party.mode=='forget' then
local value=text(Party._forgetPrompt or 'Which move?')
V.Gen3FieldUI.dialogue({value},{value},false,0)
V.Gen3FieldUI.choices(Party._forgetMoves,Party._forgetCursor,1,{opaque=true})
elseif Party.mode=='stat_growth' then
local value=text(Party._messageText or 'Level up!')
V.Gen3FieldUI.dialogue({value},{value},true,0)
local rows={};local keys={'maxHp','atk','def','spa','spd','spe'}
local names={'HP','ATTACK','DEFENSE','SP. ATK','SP. DEF','SPEED'}
for i,key in ipairs(keys) do
local n=(Party._statGrowthNew or {})[key] or 0
local value=Party._statGrowthPage==1 and string.format('%+d',n-((Party._statGrowthOld or {})[key] or 0)) or tostring(n)
rows[i]=names[i]..'  '..value
end
V.Gen3FieldUI.choices(rows,0,1,{opaque=true})
end
end
Party.handleInput=function(input,...)
if req('src.core.game3.display').planesBroken or not gridModes[Party.mode] or Party._hpAnim or Party._pokedude or Party._tutorAutoSlot or not Party.open then return pi(input,...) end
local dir
for _,key in ipairs({'up','down','left','right'}) do if input:wasPressed(key) then dir=key;break end end
if not dir then return pi(input,...) end
local old=Party.cursor
Party.cursor=M.gridIndex(old,#(Party._party or {}),dir,Party.mode=='choose_multi')
if old~=Party.cursor then
pcall(function() req('src.core.game3.audio').playSe(req('src.core.game3.se_ids').resolve('SE_SELECT')) end)
end
local filtered=setmetatable({wasPressed=function(_,key)
if key=='up' or key=='down' or key=='left' or key=='right' then return false end
return input:wasPressed(key)
end},{__index=function(_,key) local v=input[key];return type(v)=='function' and function(_,...) return v(input,...) end or v end})
return pi(filtered,...)
end
local Bag=req('src.ui.game3.bag_menu');local bd=Bag.draw
Scene.register(Bag,function(N) return N.mode~='sell' and N.mode~='party' end)
local function drawBag(native,N,skin,...)
if not N.open or N.mode=='sell' or N.mode=='party' or not O.available() then return native(...) end
M.nativePass(native,...);M.actionGrid=nil;M.bag(N,skin)
if M.actionGrid then V.Gen3FieldUI.choices(M.actionGrid.rows,M.actionGrid.index,M.actionGrid.cols) end
end
Bag.draw=function(...)
local skin=req('src.ui.game3.screens').skin('bag',Bag._session)
if skin and skin.draw then return skin.draw(Bag,...) end
return drawBag(bd,Bag,nil,...)
end
for _,path in ipairs({'src.ui.game3.rse.bag_menu','src.ui.game3.rs.bag_menu'}) do
local ok,Skin=pcall(req,path)
if ok then local draw=Skin.draw;Skin.draw=function(N,...) return drawBag(draw,N,Skin,N,...) end end
end
M.installed=true
end
return M
