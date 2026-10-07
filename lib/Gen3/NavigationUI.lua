local V=...
local req=V.engineRequire or require
local S=V.Gen3Services
local M={}
local function mapViewport(c,draw,compact)
local scale=compact and .55 or .74;local top=compact and 27 or 15
local G=love.graphics;G.push('all');G.setScissor(c.x+4*c.k,c.y+top*c.k,240*scale*c.k,160*scale*c.k)
G.translate(c.x+4*c.k,c.y+top*c.k);G.scale(c.k*scale,c.k*scale)
G.setColor(1,1,1,1);draw(G);G.pop()
end
function M.region(c,N,events,s)
c.panel(0,7,240,141)
if N.Host then
s=s or N.active();if not s then return end
local K=req('src.ui.game3.rse.scene_kit');local man=N.manifest();local map=K.image(man.layers.map.png or man.layers.map)
mapViewport(c,function(G)
if map then G.draw(map,G.newQuad(0,0,240,160,map:getDimensions()),0,0) end
G.setColor(S.accent)
for _,icon in ipairs(s.flyIcons or {}) do if icon.visible then G.rectangle('line',icon.x-3,icon.y-3,6,6) end end
if s.showPlayerIcon then G.setColor(.95,.95,.85,1);G.circle('fill',s.playerIconX*8+4,s.playerIconY*8+4,3) end
G.setColor(1,.25,.13,1);G.setLineWidth(2);G.rectangle('line',(s.cursorSx or 8)-5,(s.cursorSy or 8)-5,10,10)
end)
c.text(s.flyText and s.flyText.name or s.mapSecName or 'HOENN',186,18,48,42,5,S.accent)
c.text(s.flyText and s.flyText.sub or '',186,65,48,48,4.5,S.muted)
c.footer(s.mode=='fly' and 'D-PAD DESTINATION   A FLY   B CANCEL' or 'D-PAD EXPLORE   A / B CLOSE')
else
s=N.state();if not s then return end
local R=req('src.render.Renderer');R.worldFadeAlpha=0
local GPU=req('src.ui.game3.region_map_gpu');local names={[0]='kanto_map','sevii123_map','sevii45_map','sevii67_map'}
local region=s.bg0 and s.bg0.region or s.selectedRegion or 0
mapViewport(c,function(G)
G.draw(GPU.image(names[region] or names[0]),0,0)
if s.bg0 and s.bg0.navelPatch then G.draw(GPU.image('navel_rock_patch'),104,88) end
if s.bg0 and s.bg0.birthPatch then G.draw(GPU.image('birth_island_patch'),168,128) end
G.setColor(S.accent);for _,icon in ipairs(s.icons and s.icons.fly or {}) do if icon.visible then G.rectangle('line',icon.x*8+33,icon.y*8+33,6,6) end end
if region==s.playersRegion then G.setColor(.95,.95,.85,1);G.circle('fill',8*N.playerX+36,8*N.playerY+36,3) end
if not s.switch then G.setColor(1,.25,.13,1);G.setLineWidth(2);G.rectangle('line',8*N.cursorX+31,8*N.cursorY+31,10,10) end
if not s.switch and s.bg2 and s.bgShown and s.bgShown[2] then
local img=s.bg2.image and GPU.image(s.bg2.image) or s.bg2.preview and req('src.ui.game3.map_preview_screen').image(s.bg2.preview)
if img then G.setColor(1,1,1,1);G.draw(img,0,0) end
end
end,s.switch~=nil)
if s.switch then
local regions={'KANTO','SEVII 1 - 3','SEVII 4 - 5','SEVII 6 - 7'};local rows={}
for i=1,s.switch.maxSelection+1 do rows[i]=regions[i] end
c.text('SELECT REGION',145,17,90,13,5,S.accent)
c.rows(rows,s.switch.currentSelection+1,141,36,94,22)
c.footer('UP / DOWN REGION   A SELECT   B CANCEL')
else
c.text(s.text and s.text.map or '',186,18,48,42,5,S.accent)
c.text(s.text and s.text.dungeon or '',186,65,48,45,4.5,S.muted)
c.footer(N.mode=='fly' and 'D-PAD DESTINATION   A FLY   B CANCEL' or 'D-PAD EXPLORE   A SELECT / PREVIEW   B BACK')
end
end
M.last={owner=N,page='map',regionSelection=s and s.switch and s.switch.currentSelection}
end
function M.hof(c,N,events)
local list={};for _,mon in ipairs(N._teams[N._team] or {}) do if (tonumber(mon.species) or 0)~=0 then list[#list+1]=mon end end
if N._corrupted then c.panel(0,7,240,141);S.replay(c,events);return end
local P=req('src.core.game3.pokemon');local rows={}
for i,mon in ipairs(list) do rows[i]=P.displayMonName(mon)..'  Lv. '..tostring(mon.level or 0) end
c.panel(0,7,99,141);local mon=list[N._mon];if mon then c.model(mon,1,10,97,130,N) end
c.rows(rows,N._mon,104,29,136,19)
c.text('HALL OF FAME  '..tostring(N._number),110,10,125,13,6,S.accent)
c.footer('↑ / ↓ POKéMON   A NEXT TEAM / CLOSE   B BACK')
M.last={owner=N,page='hall_of_fame'}
end
function M.install()
if M.installed then return end
S.wrap(req('src.ui.game3.region_map'),'REGION MAP',M.region)
S.wrap(req('src.ui.game3.hall_of_fame_pc'),'HALL OF FAME',M.hof)
local ok,N=pcall(req,'src.ui.game3.rse.region_map');if ok then S.wrap(N,'REGION MAP / HOENN',M.region,N.Host) end
if V.Gen3PokenavUI then V.Gen3PokenavUI.install() end
M.installed=true
end
return M
