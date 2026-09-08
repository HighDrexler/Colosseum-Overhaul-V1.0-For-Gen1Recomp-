local savedLove=love
local x,y,button=500,300,false
love={graphics={getDimensions=function()return 1000,800 end},keyboard={isDown=function()return false end},mouse={getPosition=function()return x,y end,isDown=function(b)return button==b end}}
local combat=nil
local F=assert(loadfile('lib/FreeLookCamera.lua'))({DoublesRuntime={combat=function()return combat end}})
local screen={phase='menu',game={save={}}};local ctx={battle=screen,arena={}}
local base={eye={30,20,40},focus={0,5,0},fov=.8}
assert(F.allowed(ctx) and not F.pose(ctx,base))
button=2;assert(not F.pose(ctx,base));x=x+50
local pose=assert(F.pose(ctx,base));assert(pose.eye[1]~=base.eye[1])
button=false;assert(F.pose(ctx,base),'view did not persist during commands')
screen.phase='attack';assert(not F.pose(ctx,base) and not F.state.focus,'cinematic handoff retained manual pose')
screen.phase='menu';button=2;x=10;F.pose(ctx,base);x=400;assert(not F.pose(ctx,base),'drag started over UI stole camera')
combat={core={id='test',phase='command'},consumer={states={test={page='commands'}}}}
assert(F.allowed(ctx));combat.consumer.states.test.page='bag';assert(not F.allowed(ctx))
combat.consumer.states.test.page='targets';assert(F.allowed(ctx));combat.core.phase='resolve';assert(not F.allowed(ctx))
combat=nil;screen.game.save.colosseumBattle={freeLookEnabled=false};assert(not F.allowed(ctx))
screen.game.save.colosseumBattle.freeLookEnabled=true
local tx=500
love.mouse=nil;love.touch={getTouches=function()return {1}end,getPosition=function()return tx,300 end}
F.reset();assert(not F.pose(ctx,base));tx=550;assert(F.pose(ctx,base),'touch did not orbit')
screen.phase='attack';assert(not F.pose(ctx,base),'touch held control during action')
love=savedLove

local cries={}
local R=assert(loadfile('lib/doubles/ReleasePresentation.lua'))({engineRequire=function(name)
 assert(name=='src.core.Sound');return {playCry=function(data,species,clip)assert(data and clip==11);cries[species]=(cries[species] or 0)+1 end}
end})
local rs={context={},screen={game={data={}}}}
for _,name in ipairs({'CHARIZARD','PIKACHU','DEWGONG','CLOYSTER'})do
 local r={mon={species=name}}
 R.begin(rs,r);R.update(rs,r,.8);assert(not cries[name],'cry before materialization')
 R.update(rs,r,.05);assert(cries[name]==1)
 R.update(rs,r,10);assert(cries[name]==1,'repeated release cry')
 R.finish(rs,r);R.begin(rs,r);R.update(rs,r,1);assert(cries[name]==2,'later release missing cry')
end

local C=assert(loadfile('lib/ArenaCatalog.lua'))()
local P=assert(loadfile('lib/doubles/Presenter.lua'))({})
local CSM=assert(loadfile('lib/CurrentSpriteModels.lua'))({})
local maps,pairsChecked=0,0
for name,def in pairs(C.status().definitions)do if def.pokemon and def.camera then
 local k=def.figureScale or .38
 local context={groundY=0,arena={figureScale=k,player={def.pokemon.player[1]/k,def.pokemon.player[2]/k},enemy={def.pokemon.enemy[1]/k,def.pokemon.enemy[2]/k}},services={figureScale=k,renderSize={width=1280,height=720}}}
 local c=def.camera;local b={eye={c.side,c.height,c.back},focus={c.lookX or 0,c.lookY or 5,0},fov=.8}
 for _,src in ipairs({'player-left','player-right','enemy-left','enemy-right'})do
  local other=src:match('^player') and 'enemy' or 'player'
  for _,dst in ipairs({other..'-left',other..'-right'})do
   local ax,az=P.actorAnchor(context,src);local bx,bz=P.actorAnchor(context,dst)
   local a={ax,8,az};local t={bx,22,bz}
   CSM.stadiumActors={player={actor={height=16,attachment=function()return {position=a}end}},enemy={actor={height=28,attachment=function()return {position=t}end}}}
   for _,id in ipairs({53,56,58,62,85})do
    local p,g=CSM:wazaLocalPoint(context,'player','enemy',1,{0,0,100},{moveId=id,role='attack',sourceStrict=true})
    assert(g.aimed)
    for i=1,3 do assert(math.abs(p[i]-t[i])<1e-6,name..': beam missed actual receiving slot/height')end
   end
   local psychic=CSM:wazaBasis(context,'player','enemy',2,{moveId=94,role='attack',sourceStrict=true})
   assert(psychic.origin[1]==t[1] and psychic.origin[3]==t[3],'Psychic field on attacker')
   local s={core={slots={},currentEvent={kind='move',slot=src,targets={dst}}},actors={},movePresentation={chapterAge=0}}
   local launch=P.camera(b,s,context);s.movePresentation.chapterAge=1
   local track=P.camera(b,s,context)
   local sx,sz=P.anchor(context,src);local dx,dz=P.anchor(context,dst)
   assert(math.abs(launch.focus[1]-sx)<1e-6 and math.abs(launch.focus[3]-sz)<1e-6,'launch camera missed attacker')
   assert(math.abs(track.focus[1]-(sx+dx)/2)<1e-6 and math.abs(track.focus[3]-(sz+dz)/2)<1e-6,'tracking wrong pair')
   s.core.currentEvent.targets={other..'-left',other..'-right'};s.movePresentation.chapterAge=0
   local spread=P.camera(b,s,context);s.movePresentation.chapterAge=1
   local spreadLater=P.camera(b,s,context)
   for i=1,3 do assert(spread.focus[i]==spreadLater.focus[i],'spread move started with single-target closeup')end
   pairsChecked=pairsChecked+1
  end
 end
 maps=maps+1
end end
assert(maps>=10)
print('CameraFXTests: mouse/touch handoff, UI boundaries, once-per-release cries, '..maps..' arenas / '..pairsChecked..' directed doubles pairs, attachment heights and spread framing PASS')
