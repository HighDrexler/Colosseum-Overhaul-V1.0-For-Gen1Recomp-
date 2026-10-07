
local V=...
local req=V.engineRequire or require
local S=V.Gen3Services
local M={}
local function badges(N)
if N._rse or N._man and N._man.cardType=='rs' then
local K=req('src.ui.game3.rse.scene_kit');local man=K.manifest('rse/trainer_card')
return man and K.image(man.badges.png)
end
if M.badgeImage==nil then
local raw=req('src.core.game3.dataset').cache():read('data/generated/gba/trainer_card/badges.rgba')
M.badgeImage=raw and love.graphics.newImage(love.image.newImageData(128,16,'rgba8',raw)) or false
end
return M.badgeImage or nil
end
function M.trainer(c,N,events)
local data=N._card or {};local G=love.graphics
G.push('all')
if N._flip then
local scale=math.max(.02,(160-2*N._flip.top)/160)
G.translate(0,c.y+80*c.k);G.scale(1,scale);G.translate(0,-c.y-80*c.k)
end
c.panel(0,7,240,140)
c.text(data.playerName or data.name or '',8,14,157,16,9)
c.text(string.format('ID %05d',data.trainerId or 0),169,16,64,12,5,S.accent,'right')
if N.side=='front' then
c.text('TRAINER RECORD',8,39,216,11,5,S.muted)
local rows={{'MONEY',tostring(data.money or 0)},{'POKéDEX',data.hasPokedex and tostring(data.pokedexSeen or data.caughtMonsCount or 0) or 'NOT OBTAINED'},
{'PLAY TIME',string.format('%d:%02d',data.playTimeHours or 0,data.playTimeMinutes or 0)}}
for i,row in ipairs(rows) do local y=56+(i-1)*18;c.panel(7,y,225,17);c.text(row[1],13,y+3,113,11,5,S.muted);c.text(row[2],125,y+3,100,11,5,S.ink,'right') end
c.text('LEAGUE BADGES',8,112,135,10,4.5,S.muted)
local art=badges(N)
for i=1,8 do local x=8+(i-1)*28;local got=data.badges and data.badges[i]
c.panel(x,126,25,16,got)
if got and art then c.image(art,x+6,127,13,14,G.newQuad((i-1)*16,0,16,16,art:getDimensions()))
else c.text(tostring(i),x+3,129,19,9,5,got and S.accent or S.muted,'center') end
end
else
local rows=N.texts and N.texts(data,'back',N._printColon)
or (N._rse and N.backTextsRse or N.backTexts)(data)

for _,row in ipairs(rows) do if row.y>28 then c.text(row.text,row.x,row.y+4,240-row.x-8,14,5,row.stat and S.accent or S.ink) end end
end
G.pop();c.footer(N.side=='front' and 'A TURN CARD   B CLOSE' or 'A CLOSE   B TURN CARD')
end
local function facade(N,species)
if not N._cbeMon or N._cbeMonSource~=N._mon or N._cbeMon.species~=species then
local m={};for k,v in pairs(N._mon or {}) do m[k]=v end
m.species=species;m.speciesNumbering='internal';m.isEgg=false;m.egg=false
N._cbeMon=m;N._cbeMonSource=N._mon
end
return N._cbeMon
end
function M.progress(c,N,events,egg)
c.panel(0,7,240,103)
local G=love.graphics
if egg and N._eggShown then


local eggs=N._sheets and N._sheets.hatch
if eggs then c.image(eggs.image,101+(N._eggOffset or 0),39,38,38,eggs.quads[N._eggFrame or 0] or eggs.quads[0])
else local pic=req('src.core.game3.pokemon').frontPic(req('src.core.game3.pokemon').SPECIES_EGG)
if pic then c.image(pic.image,95+(N._eggOffset or 0),25,50,73) end
end
elseif not (not egg and V.Gen3EvolutionModels and V.Gen3EvolutionModels.draw(c,N)) then
local species=egg and N._species or N._preSpecies
if not egg then
local pre={fade_in=true,intro_msg=true,intro_cry=true,intro_sound=true,start_music=true,cycle=true,cancel=true}
if not pre[N._state] then species=N._postSpecies end
end
if species then c.model(facade(N,species),66,9,108,99,N) end
end
if egg then
local art=N._sheets and N._sheets.shard
if art then for _,shard in ipairs(N._shards or {}) do
c.image(art.image,116+shard.ax/256,46+shard.ay/256,8,8,art.quads[shard.frame] or art.quads[0])
end end
else
for _,p in ipairs(N._particles or {}) do
G.setColor(1,.89,.51,math.min(1,(p.maxT-p.t)/10));G.circle('fill',c.x+p.x*c.k,c.y+(p.y*.83+7)*c.k,(p.size or 2)*c.k)
end
end
local flash=N._flashAlpha or 0
if flash>0 then G.setColor(1,1,1,flash);G.rectangle('fill',c.x,c.y+7*c.k,240*c.k,103*c.k) end
c.panel(0,115,240,33)
local Message=req('src.ui.game3.message')
if Message.isOpen() then c.text(V.Gen3Screens.messageText(Message):gsub('\n',' '),7,119,226,25,5.7) end
S.replay(c,events,function(e)return e.kind=='cursor' or ((e.kind=='panel' or e.kind=='text') and e.y<115 and e.x>130) end)
c.footer(egg and 'A CONTINUE' or (N._canStop and 'B CANCEL DURING EVOLUTION   A CONTINUE' or 'A CONTINUE'))
M.last={owner=N,state=N._state,species=N._cbeMon and N._cbeMon.species}
end
function M.install()
if M.installed then return end
local Stats=req('src.ui.game3.stat_growth');local statsDraw=Stats.draw
Stats.draw=function(...)
if not Stats.isOpen() or not V.Gen3Overlay.available() then return statsDraw(...) end
return V.Gen3Overlay.paint(function(w,h)
local c=S.canvas(w,h);local gains=Stats._page==1
c.panel(143,7,97,132);c.text(gains and 'LEVEL UP' or 'TOTAL STATS',150,12,83,13,5.5,S.accent)
local old,new=Stats._oldStats or {},Stats._newStats or {}
local labels={'HP','ATTACK','DEFENSE','SP. ATK','SP. DEF','SPEED'}
for i,key in ipairs({'maxHp','atk','def','spa','spd','spe'}) do
local n=(new[key] or 0)-(gains and (old[key] or 0) or 0)
c.text(labels[i],150,30+(i-1)*14,55,13,4.5)
c.text((gains and n>=0 and '+' or '')..n,206,30+(i-1)*14,27,13,5,nil,'right')
end
c.text('A / B CONTINUE',150,120,83,12,3.9,S.muted)
end)
end
S.wrap(req('src.ui.game3.trainer_card'),'TRAINER CARD',M.trainer)
local okRs,RsCard=pcall(req,'src.ui.game3.rs.trainer_card')
if okRs then S.wrap(RsCard,'TRAINER CARD',M.trainer) end
S.wrap(req('src.ui.game3.evolution_scene'),'EVOLUTION',function(c,N,e) M.progress(c,N,e,false) end)
if V.Gen3EvolutionModels then V.Gen3EvolutionModels.install() end
S.wrap(req('src.ui.game3.egg_hatch'),'EGG HATCH',function(c,N,e) M.progress(c,N,e,true) end)
local found,RsHatch=pcall(req,'src.ui.game3.rs.egg_hatch')
if found then
V.Gen3MenuScene.register(RsHatch)
local native=RsHatch.draw
RsHatch.draw=function(...)
local scene=RsHatch._scene
if not scene or scene.headless or not V.Gen3Overlay.available() then return native(...) end
local sprites=scene:sp();local shown=sprites.oamShown;local filtered={};local frontVisible=false


for _,entry in ipairs(shown or {}) do
if scene.frontSheet and entry.sheet==scene.frontSheet then frontVisible=true
else filtered[#filtered+1]=entry end
end
local models=V.Gen3Runtime.prefs().menuModels~=false
if models then sprites.oamShown=filtered end
local result={pcall(S.capture,native,...)};sprites.oamShown=shown
if not result[1] then error(result[2],0) end
local events=result[2];local image=V.Gen3Menus.scratch
return V.Gen3Overlay.paint(function(w,h)
local c=S.canvas(w,h);c.header('EGG HATCH');c.panel(0,7,240,103)
c.image(image,0,7,240,103,love.graphics.newQuad(0,0,240,110,image:getDimensions()))
if frontVisible and models then
if scene._cbeSourceMon~=scene.mon then
local mon={};for k,v in pairs(scene.mon) do mon[k]=v end
mon.isEgg=false;mon.egg=false;scene._cbeMon=mon;scene._cbeSourceMon=scene.mon
end
c.model(scene._cbeMon,66,9,108,99,RsHatch)
end
c.panel(0,115,240,33)
S.replay(c,events,function(e)return e.kind=='text' and e.y>=115 end)
if scene.choice~=nil then c.rows({'YES','NO'},scene.choice+1,172,65,68,18) end
c.footer(scene.choice~=nil and 'UP / DOWN SELECT   A CONFIRM   B SKIP' or 'A CONTINUE')
M.last={owner=RsHatch,state=scene.state,species=frontVisible and scene.species,rs=true}
end)
end
end



local B=req('src.ui.game3.bag_menu');local old=B.draw
V.Gen3MenuScene.register(B)
local function drawService(native,...)
if not B.open or (B.mode~='sell' and B.mode~='party') or not V.Gen3Overlay.available() then return native(...) end
local events=S.capture(native,...)
return V.Gen3Overlay.paint(function(w,h)
local c=S.canvas(w,h);c.header(B.mode=='sell' and 'SELL ITEMS' or 'CHOOSE POKéMON')
local flow=B.mode=='sell' and B._sell
if flow then
c.panel(0,7,104,104);c.text(flow.name,7,12,90,16,6,S.accent)
c.text('MONEY  '..tostring(flow.session.money or 0),7,33,90,13,4.5)
for _,e in ipairs(events) do if e.kind=='item' then
local G=love.graphics;G.push('all');G.translate(c.x+39*c.k,c.y+59*c.k);G.scale(c.k,c.k);e.draw(e.id,0,0);G.pop();break
end end
c.panel(110,7,130,104)
c.text('QUANTITY  '..tostring(flow.qty)..' / '..tostring(req('src.core.game3.bag').get(B._bag,flow.itemId)),117,15,116,16,6)
c.text('SALE VALUE  '..tostring(flow:total()),117,39,116,16,5,S.accent)
if flow.state=='confirm' then c.rows({'YES','NO'},flow.yesNo,116,65,118,19) end
c.panel(0,117,240,31);c.text(tostring(flow.text or ''):gsub('\n',' '),7,122,226,21,5.5)
c.footer('D-PAD QUANTITY / SELECT   A CONFIRM   B CANCEL')
else c.panel(0,7,240,141);S.replay(c,events) end
S.lastDraw={module=B,title='BAG SERVICE'}
end)
end
B.draw=function(...) return drawService(old,...) end
for _,path in ipairs({'src.ui.game3.rse.bag_menu','src.ui.game3.rs.bag_menu'}) do
local ok,Skin=pcall(req,path)
if ok then local draw=Skin.draw;Skin.draw=function(...) return drawService(draw,...) end end
end
M.installed=true
end
return M
