-- Actual packaged portrait textures + shipped compact portrait functions.
-- Synthetic game data; not a live save/battle. No source disc is required.
local root=assert(os.getenv('CBE_MOD_ROOT'),'set CBE_MOD_ROOT')
local output=assert(os.getenv('CBE_RENDER_OUT'),'set CBE_RENDER_OUT to an existing directory')
local function read(p)local f=assert(io.open(p,'rb'));local b=f:read('*a');f:close();return b end
local s=read(root..'/UIMain.lua')
local function section(a,b)local x=assert(s:find(a,1,true));local y=assert(s:find(b,x+#a,true));return s:sub(x,y-1)end
local calls,images=0,0
local G={monIsShiny=assert(loadfile(root..'/lib/ShinySupport.lua'))().isShiny}
local cache=assert(loadfile(root..'/lib/UIVisualCache.lua'))({bounds=assert(loadfile(root..'/assets/portrait_bounds.lua'))()})
local ColosseumUI={};G.ColosseumUI=ColosseumUI
local owner={read=function()return true end,assets={}}
function owner.assets:image(p)
 images=images+1;return love.graphics.newImage(love.filesystem.newFileData(read(root..'/'..p),p))
end
local env=setmetatable({GoldCompat=G,ColosseumUI=ColosseumUI,State={visualCache=cache},modRef=owner,
 colosseumIconsEnabled=true,colosseumIconCache={},featureEnabled=function()return true end,
 partyLogicalCanvas=function()return 0,0,1 end},{__index=_G})
local body=section('local COLOSSEUM_ICON_FRAMES = {','local dramatic = {')
 ..section('local function drawStadiumPortrait(','local function visibleBounds(')
 ..section('function ColosseumUI.drawPortrait(','function ColosseumUI.drawDialogue(')
 ..section('function GoldCompat.drawColosseumPortrait(','-- Colosseum Party keeps the native')
local f=assert(loadstring(body));setfenv(f,env);f()
G.drawSelectedMenuModel=function()calls=calls+1;error('portrait unexpectedly requested a 3D actor')end
G.drawCleanResolvedPortrait=G.drawSelectedMenuModel
local game={data={pokemon={}}};for i=1,251 do game.data.pokemon['MON'..i]={dex=i}end
local list={{246,'LARVITAR'},{156,'QUILAVA'},{175,'TOGEPI'},{59,'ARCANINE'},{163,'HOOTHOOT'},{58,'SHINY GROWLITHE',true}}
function love.load()
 -- Execute the restored UI routing for all 502 appearances against the actual
 -- packaged texture files. The game/save state is synthetic, not a battle.
 for _,gen in ipairs{1,2}do
  game.generation=gen
  for d=1,251 do for _,shiny in ipairs{false,true}do
   assert(G.drawColosseumPortrait(game,{species='MON'..d,shiny=shiny},0,0,64,64),'portrait missing '..d)
  end end
 end
 assert(calls==0,'model requested for atlas card');print('PASS 1004 Gen I/II portrait requests; 502 actual appearance images; 0 model requests')
end
local frame=0
function love.draw()
 local g=love.graphics;g.clear(.03,.05,.055,1)
 g.setFont(g.newFont(26));g.setColor(.9,.94,.9,1);g.print('RESTORED COLOSSEUM PORTRAIT ROUTE',54,28)
 for i,row in ipairs(list)do
  local x=55+((i-1)%3)*395;local y=92+math.floor((i-1)/3)*295
  g.setColor(.12,.22,.23,1);g.rectangle('fill',x,y,370,263)
  assert(G.drawColosseumPortrait(game,{species='MON'..row[1],shiny=row[3]},x+55,y+14,260,196))
  g.setColor(.9,.94,.9,1);g.setFont(g.newFont(18));g.printf(row[2],x,y+232,370,'center')
 end
 frame=frame+1
 if frame==2 then g.captureScreenshot(function(data)
  local f=assert(io.open(output..'/restored-portraits.png','wb'));f:write(data:encode('png'):getString());f:close();love.event.quit()
 end)end
end
function love.errorhandler(msg)print(debug.traceback(msg,2));os.exit(1)end
