-- Actual shipped UI functions, isolated from engine-dependent menus.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local f=assert(io.open(root..'/UIMain.lua','rb'));local src=f:read('*a');f:close()
local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local function section(a,b)local x=assert(src:find(a,1,true));local y=assert(src:find(b,x+#a,true));return src:sub(x,y-1)end
local support=assert(loadfile(root..'/lib/ShinySupport.lua'))()
local G={__shinySupport=support,__stadiumUiActors={},__stadiumUiPending={}}
local env=setmetatable({GoldCompat=G,love={graphics={}}},{__index=_G})
local code=section('function GoldCompat.monIsShiny(','-- Safari ownership')
 ..section('function GoldCompat.stadiumUiVariant(','function GoldCompat.informationAnimationDwell(')
 ..section('function GoldCompat.stadiumUiMonKey(','function GoldCompat.stadiumUiMatMul(')
 ..section('function GoldCompat.drawStadiumUiModel(','function GoldCompat.drawCleanResolvedPortrait(')
local chunk=assert(loadstring(code,'@shipped-ui-shiny-functions'));setfenv(chunk,env);chunk()
local mon={species='PIKACHU',dvs={attack=10,defense=10,speed=10,special=10},hp=77}
local original={species=mon.species,hp=mon.hp,dvs=mon.dvs}
yes(G.monIsShiny(mon),'DV-only UI shiny');yes(G.stadiumUiVariant(mon)=='shiny','portable model variant')
yes(G.stadiumUiMonKey(mon)=='PIKACHU:shiny','canvas and actor key includes variant')
local proxy=G.spriteResolutionMon(mon)
yes(proxy~=mon and proxy.shiny and mon.shiny==nil,'sprite context proxy, no save mutation')
yes(proxy.dvs==mon.dvs and proxy.hp==77,'nonvisual values unchanged')
local queued,peeked,drawn={},{},{}
local selected=true;local statusDraws=0
G.colosseumModelsSelected=function()return selected end
G.expireCompactModelSlots=function()end
G.drawColosseumModelStatus=function()statusDraws=statusDraws+1;return true end
local api={shinySupportVersion=1,peek=function(source,dex,variant)peeked[#peeked+1]=variant;return {resident=false}end,
 acquire=function()error('must not extract from UI draw')end}
G.stadiumUiClock=function()return 1 end
G.cbeInformationModelService=function(game,m,kind)return api,'cbe:colosseum-pokemon',{}end
G.stadiumUiDexNumber=function()return 25 end
G.stadiumUiCachedActor=function()end;G.stadiumUiCache=function()return false end
G.touchCbeInformationViewer=function()end;G.stadiumUiSelectionSettled=function()return true end
G.requestCbeInformationResident=function(game,m,kind,key)queued[#queued+1]={mon=m,kind=kind,key=key};return true end
G.drawCleanResolvedPortrait=function(game,m,x,y,w,h,kind)drawn[#drawn+1]={mon=m,kind=kind};return 'resolved-shiny-sprite'end
for _,generation in ipairs{'gen1','gen2'}do
 local game={generation=generation}
 for _,surface in ipairs{'summary','pokedex','pc','evolution','hatch'}do
  local result=G.drawInformationPortrait(game,mon,10,10,100,100,surface,surface)
  yes(result==true and statusDraws>0,'explicit pending state '..generation..'/'..surface)
  yes(peeked[#peeked]=='shiny' and queued[#queued].mon==mon,'exact variant queued')
  yes(queued[#queued].kind==surface,'surface ownership retained')
  yes(#drawn==0,'no alternate-source fallback while model is pending')
 end
end
local oldQueue=#queued;api.shinySupportVersion=nil
assert(G.drawInformationPortrait({},mon,0,0,100,100,'summary','summary')==true)
yes(#queued==oldQueue,'old separate CBE does not loop impossible shiny preparation')
api.shinySupportVersion=1
local originalDraw=G.drawStadiumUiModel
for _,result in ipairs{false,'pending','warming'}do
 G.drawStadiumUiModel=function()return result end
 yes(G.drawInformationPortrait({},mon,0,0,30,30,'summary','summary')==true,'truthy pending is not success')
end
G.drawStadiumUiModel=function()error('GPU upload failed')end
yes(G.drawInformationPortrait({},mon,0,0,30,30,'summary','summary')==true,'renderer failure consumes pod with explicit status')
local before=#drawn;G.drawStadiumUiModel=function()return true end
yes(G.drawInformationPortrait({},mon,0,0,30,30,'summary','summary')==true and #drawn==before,'ready 3D owns pod exactly once')
G.drawStadiumUiModel=originalDraw
selected=false
G.cbeInformationModelService=function()return nil end
yes(G.drawInformationPortrait({},mon,0,0,30,30,'summary','summary')=='resolved-shiny-sprite','provider OFF stays resolved source')
yes(mon.species==original.species and mon.hp==original.hp and mon.dvs==original.dvs and mon.shiny==nil,'no gameplay or shiny state edits')
print('ShinyUIPipelineTests: '..checks..' checks passed; extracted shipped functions with UI mocks')
