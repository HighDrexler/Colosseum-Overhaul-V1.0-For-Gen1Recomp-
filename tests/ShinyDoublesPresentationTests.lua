local H=assert(loadfile('tests/support/ShinyHarness.lua'))();local h=H.new()
local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
h.putModel(25);h.putMetadata(25,h.filter);h.putModel(6);h.putMetadata(6,h.filter)
local V={PokemonActors=h.A,ShinySupport=h.Shiny,CurrentSpriteModels={drawn={},presented={}}}
local P=assert(loadfile('lib/doubles/Presenter.lua'))(V)
local s={generation=1,screen={game=h.game},core={slots={},message=function()error('visual failure must not insert battle text')end},actorOrder={},actors={},
 context={game=h.game,groundY=0,arena={player={0,60},enemy={0,-60},figureScale=.38},services={vp={},renderSize={width=1000,height=700}}}}
local mons={{species='TEST'},{species='TEST',dvs={attack=10,defense=10,speed=10,special=10}},{species='RARE'},{species='RARE',shiny=true}}
for i,id in ipairs{'player-left','player-right','enemy-left','enemy-right'}do
 local r={slot=id,battlerId='mon'..i,mon=mons[i],battler={mon=mons[i]},visible=true,spawnProgress=1}
 s.actorOrder[i]=r;s.actors[r.battlerId]=r;s.core.slots[id]={side=id:match('^player') and 'player' or 'enemy',mon=mons[i],battlerId=r.battlerId}
end
for i=1,4 do P.update(s,.02)end
for i,r in ipairs(s.actorOrder)do
 yes(r.actor~=nil,'all four slots have models');yes(r.actor.variant==(i%2==0 and 'shiny' or 'normal'),'each slot correct variant')
 yes(r.mon==mons[i] and s.core.slots[r.slot].mon==mons[i],'slot identity unmodified')
end
yes(s.actorOrder[1].actor.scene==s.actorOrder[2].actor.scene,'same native-filter species shares geometry')
yes(s.actorOrder[3].actor.scene~=s.actorOrder[4].actor.scene,'same rare-model species does not share body')
yes(P.draw(s,s.context),'four-slot draw');yes(h.draws==4,'every slot drawn once')
yes(h.shader.uniforms.shinyEnabled[1]==0,'rare model resets preceding native filter')
-- Renderer errors are forwarded with the native session's screen.game;
-- sessions have no s.game field and must not silently drop the report.
local faultGame,faultText
V.BattleCache={noteRenderError=function(game,why)faultGame,faultText=game,why end}
local realRenderer=h.A.service.withRenderer
h.A.service.withRenderer=function()return false,'controlled GPU rejection'end
P.draw(s,s.context);yes(faultGame==s.screen.game and faultText=='controlled GPU rejection','renderer rejection opens correct game barrier')
h.A.service.withRenderer=realRenderer
local originalDraw=s.actorOrder[1].actor.draw
s.actorOrder[1].actor.draw=function()error('controlled draw failure')end
P.draw(s,s.context);yes(faultGame==s.screen.game and tostring(faultText):find('controlled draw failure',1,true),'draw failure not hidden by pcall')
s.actorOrder[1].actor.draw=originalDraw
-- Unavailable native recipe -> explicit readiness error; NEVER a sprite; later recovery resumes 3D.
local h2=H.new();h2.putModel(25);h2.putMetadata(25,nil);h2.source=false
local image={getDimensions=function()return 48,48 end}
local C={PokemonActors=h2.A,ShinySupport=h2.Shiny,CurrentSpriteModels={drawn={},presented={}}}
local reported
C.BattleCache={noteRenderError=function(game,err)reported=err end}
local P2=assert(loadfile('lib/doubles/Presenter.lua'))(C)
local mon={species='TEST',shiny=true};local r={slot='player-left',battlerId='shiny',mon=mon,battler={mon=mon,sprite=image},visible=true}
local t={generation=1,screen={game=h2.game},core={slots={['player-left']={side='player',mon=mon}},message=function()error('unexpected gameplay message')end},actors={shiny=r},actorOrder={r},
 context={game=h2.game,groundY=0,arena={player={0,60},enemy={0,-60},figureScale=.38},services={vp={},renderSize={width=1000,height=700},project=function()return 200,300 end}}}
P2.update(t,.02);yes(not r.actor and not r.spriteMode and r.retryAt and reported,'failure reports strict-model error and schedules retry')
P2.draw(t,t.context);yes(h2.draws==0,'no fallback sprite is drawn while Colosseum is selected')
h2.source=true;t.visualClock=3;P2.update(t,.02);yes(r.actor and r.actor.shinyFilter and not r.spriteMode,'recovered source replaces fallback with real shiny')
yes(mon.shiny==true and t.core.slots['player-left'].mon==mon,'recovery does not edit shiny or battle records')
print('ShinyDoublesPresentationTests: '..checks..' checks passed; four active slots, mocked GPU')
