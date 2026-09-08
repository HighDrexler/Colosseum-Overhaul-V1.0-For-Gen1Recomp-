-- Execute the shipped compact-cell source arbitration functions. No native
-- battle/model renderer or texture extraction is substituted into these checks.
local f=assert(io.open('UIMain.lua','rb'));local s=f:read('*a');f:close()
local function section(a,b)local x=assert(s:find(a,1,true));local y=assert(s:find(b,x+#a,true));return s:sub(x,y-1)end
local checks=0;local function yes(v,k)checks=checks+1;assert(v,k)end
local selected=true;local icons=true;local iconCalls=0;local requests={};local spriteReads=0;local spritesDrawn=0
local G={colosseumModelsSelected=function()return selected end}
local graphics={push=function()end,pop=function()end,origin=function()end,setColor=function()end,
 getScissor=function()end,setScissor=function()end,
 transformPoint=function(x,y)return 10+x*4.5,20+y*4.5 end,
 draw=function()spritesDrawn=spritesDrawn+1 end}
local image={getDimensions=function()return 16,16 end}
local env=setmetatable({GoldCompat=G,love={graphics=graphics},spritePortraitResolver={resolve=function()spriteReads=spriteReads+1;return image end},
 featureEnabled=function()return icons end,partyLogicalCanvas=function()return 10,20,4.5 end},{__index=_G})
local body=section('function GoldCompat.drawSelectedMenuModel(','-- Colosseum Party keeps the native')
 ..section('function GoldCompat.drawCleanResolvedPortrait(','function GoldCompat.genderSymbol(')
 ..section('local function drawPCCompactIcon(','local function pcItemName(')..'\nreturn drawPCCompactIcon'
local chunk=assert(loadstring(body,'@shipped-strict-menu-cells'));setfenv(chunk,env);local compact=chunk()
G.prepareCleanResolvedPortrait=function(i,m)return i,m end
G.drawInformationPortrait=function(game,mon,x,y,w,h,kind,spriteKind,serviceKind)
 requests[#requests+1]={game=game,mon=mon,x=x,y=y,w=w,h=h,kind=kind,serviceKind=serviceKind};return true
end
G.drawColosseumModelStatus=function()return true end
G.ColosseumUI={setIconsEnabled=function()end,drawPortrait=function()iconCalls=iconCalls+1;return true end}
for _,gen in ipairs{1,2}do
 local game={generation=gen};local mon={species='VOLTORB',shiny=true}
 for _,kind in ipairs{'party','summary','pc','dex','evolution','hatch','hud'}do
  yes(G.drawCleanResolvedPortrait(game,mon,11.125,30.25,44.55,29.15,kind),'fractional viewport cell succeeds')
  local r=requests[#requests];yes(r.kind:match('^portrait:') and r.serviceKind==r.kind,'unique queue slot for cell')
  yes(r.mon==mon and r.game==game,'shiny wrapper preserved')
 end
 local r=requests[#requests];local same=r.kind
 G.drawCleanResolvedPortrait(game,{species='QUILAVA'},11.125,30.25,44.55,29.15,'hud')
 yes(requests[#requests].kind==same,'new species replaces same cell rather than leaking slots')
 G.drawCleanResolvedPortrait(game,mon,71.125,30.25,44.55,29.15,'hud')
 yes(requests[#requests].kind~=same,'two displayed cells do not supersede each other')
 local before=#requests;local beforeIcons=iconCalls
 yes(G.drawColosseumPortrait(game,mon,4,8,16,16),'party uses approved Colosseum headshot')
 yes(iconCalls==beforeIcons+1 and #requests==before,'party atlas does not queue a 3D body')
 yes(compact(game,mon,4,8,16,16,true,0),'PC compact icon keeps approved headshot')
 yes(iconCalls==beforeIcons+2 and #requests==before,'PC headshot does not queue a model')
 icons=false
 yes(G.drawColosseumPortrait(game,mon,4,8,16,16),'explicit icons OFF falls back to selected 3D body')
 r=requests[#requests];yes(r.x==28 and r.y==56 and r.w==72,'logical transform applied once')
 yes(compact(game,mon,4,8,16,16,true,0),'PC icons OFF still obeys exclusive Colosseum 3D route')
 icons=true
end
yes(spriteReads==0 and spritesDrawn==0,'no Battle Arts/native sprite resolver consulted while selected')
selected=false;icons=false;G.ColosseumUI.drawPortrait=function()return false end
yes(G.drawCleanResolvedPortrait({}, {species='VOLTORB'},0,0,20,20,'party'),'OFF keeps resolved sprite route')
yes(spriteReads==1 and spritesDrawn==1,'OFF uses resolver exactly once')
selected=true
yes(G.drawCleanResolvedPortrait({}, {species='EGG',isEgg=true},0,0,20,20,'party'),'egg icon remains native instead of asking for unsupported species')
yes(spriteReads==2,'egg does not request Pokemon body')
print('StrictUIRoutingTests: '..checks..' checks PASS; shipped cell functions, graphics and provider fixtures')
