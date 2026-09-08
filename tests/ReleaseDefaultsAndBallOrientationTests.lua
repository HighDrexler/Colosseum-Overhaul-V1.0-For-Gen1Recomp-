local checks=0;local function yes(x,k)checks=checks+1;assert(x,k)end
local function near(a,b,k)yes(math.abs(a-b)<1e-8,k)end
local S=assert(loadfile('lib/BattleSettings.lua'))()
local fresh={save={}};local p=S.prefs(fresh)
yes(p.doubleBattlesEnabled and p.abilitiesEnabled,'fresh default ON')
local old={save={colosseumBattle={doubleBattlesEnabled=false,abilitiesEnabled=false,freeLookEnabled=false},party={{hp=77}}}}
local q=S.prefs(old);yes(not q.doubleBattlesEnabled and not q.abilitiesEnabled and not q.freeLookEnabled,'explicit saved OFF retained')
yes(old.save.party[1].hp==77,'save gameplay unmodified')
local function read(path)local f=assert(io.open(path,'rb'));local t=f:read('*a');f:close();return t end
local manifest=read('manifest.json');yes(manifest:match('"experimental"%s*:%s*false'),'mod experimental tag removed')
local settings=read('lib/BattleSettings.lua');yes(not settings:find('(TEST)',1,true),'option labels no TEST')
local runtime=read('lib/doubles/Runtime.lua');yes(runtime:find('experimental=false',1,true),'public doubles capability no experimental')
local V={};V.DoublesPresenter=assert(loadfile('lib/doubles/Presenter.lua'))(V)
V.MoveFXExtractor={peek=function()return nil end}
-- Provide a minimal source-open chapter but no particles: only matrix ownership is tested.
V.MoveFXExtractor.peek=function()return {wazaPhases={}}end
V.WazaPhasePolicy={select=function(s)return s end};V.WazaSequenceRuntime={resolveEntryStarts=function()return {}end}
local captured;V.WazaHandlers={drawAsset=function(_,asset,vp,m)captured=m;return true end}
local R=assert(loadfile('lib/doubles/ReleasePresentation.lua'))(V)
for _,axis in ipairs{{{0,60},{0,-60}},{{12,24},{-17,-33}},{{-30,-12},{25,17}}}do
 local context={groundY=0,arena={player=axis[1],enemy=axis[2],figureScale=.38},services={figureScale=.38,stageVP={}}}
 for _,side in ipairs{'player','enemy'}do for _,lane in ipairs{'left','right'}do
  local rec={slot=side..'-'..lane,mon={},visible=true};local session={context=context,actorOrder={rec}}
  R.begin(session,rec);rec.release.models={{asset={},start=0,stop=30}};R.draw(session,context)
  local x,z,dx,dz=V.DoublesPresenter.anchor(context,rec.slot);local len=math.sqrt(dx*dx+dz*dz)
  near(captured[4],x,'open prop stays exact lane X');near(captured[12],z,'open prop stays exact lane Z')
  near(captured[3]/1.1,dx/len,'verified native +Z button follows actor X');near(captured[11]/1.1,dz/len,'verified native +Z button follows actor Z')
  near(rec.release.geometry.target[1]-rec.release.geometry.origin[1],dx/len,'emitter direction same prop')
 end end
end
print('ReleaseDefaultsAndBallOrientationTests: '..checks..' checks passed; synthetic stage transforms')
