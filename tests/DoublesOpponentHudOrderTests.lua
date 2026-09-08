-- Presentation-only regression: enemy HUD is mirrored, controller IDs are not.
-- No game/ROM, GPU, or physical device is exercised by this headless test.
local root=os.getenv('UI_COMPAT_DIR') or '.'
local count=0
local function eq(a,b,tag)
  count=count+1;assert(a==b,tag..': '..tostring(a)..' ~= '..tostring(b))
end
local function yes(a,tag) count=count+1;assert(a,tag) end
local function near(a,b,tag) yes(math.abs(a-b)<.000001,tag) end
local function copy(t)
  if type(t)~='table' then return t end
  local out={};for k,v in pairs(t) do out[k]=copy(v) end;return out
end
local function same(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~='table' then return a==b end
  for k,v in pairs(a) do if not same(v,b[k]) then return false end end
  for k in pairs(b) do if a[k]==nil then return false end end
  return true
end
local U=assert(loadfile(root..'/lib/DoublesUI.lua'))({mod={}})
local slots={
 {id='player-left',side='player',position=1,partyIndex=1,battlerId='p1',name='ARTICUNO',species='ARTICUNO',hp=95,maxHP=100,level=75,types={'ICE','FLYING'},portrait={species='ARTICUNO'}},
 {id='player-right',side='player',position=2,partyIndex=2,battlerId='p2',name='BLASTOISE',species='BLASTOISE',hp=80,maxHP=100,level=75,types={'WATER'},portrait={species='BLASTOISE'}},
 {id='enemy-left',side='enemy',position=1,partyIndex=1,battlerId='e1',name='GENGAR',species='GENGAR',hp=70,maxHP=100,level=76,types={'GHOST','POISON'},portrait={species='GENGAR'}},
 {id='enemy-right',side='enemy',position=2,partyIndex=2,battlerId='e2',name='GOLBAT',species='GOLBAT',hp=60,maxHP=100,level=76,types={'POISON','FLYING'},portrait={species='GOLBAT'}},
}
local original=copy(slots)
for _,size in ipairs({{1280,720},{1920,1080},{2560,1440},{3840,2160},
 {1227,1008},{640,360},{568,320},{390,844},{844,390}}) do
 for _,page in ipairs({'commands','moves','targets','bag','party'}) do
  local L=U.layout(size[1],size[2],page,size[1]<640)
  local pl,pr,el,er=U.cardBounds(slots[1],L),U.cardBounds(slots[2],L),U.cardBounds(slots[3],L),U.cardBounds(slots[4],L)
  near(pl.y,L.margin,'player-left keeps upper position')
  near(pr.y,L.margin+L.ch+L.gap,'player-right keeps lower position')
  near(er.y,L.margin,'enemy-right is upper position')
  near(el.y,L.margin+L.ch+L.gap,'enemy-left is lower position')
  near(el.x,er.x,'enemy cards keep one column')
  near(el.px,er.px,'enemy portraits keep one column')
  near(pl.x,L.margin,'player horizontal geometry unchanged')
  near(pl.px,L.margin+L.cardW+4*L.u,'player portrait geometry unchanged')
  near(el.px,L.w-L.margin-L.totalW,'enemy portrait x unchanged')
  near(el.w,L.cardW,'card width unchanged');near(er.h,L.ch,'card height unchanged')
  yes(er.y+er.h<el.y,'enemy cards do not overlap')
  yes(pr.y+pr.h<L.h,'player cards stay in viewport')
  yes(el.y+el.h<L.h,'enemy cards stay in viewport')
 end
end
-- Screen mapping is keyed to each row, not array order or active-party order.
local shuffled={slots[4],slots[1],slots[3],slots[2]}
local L=U.layout(1280,720,'commands',false)
for _,r in ipairs(shuffled) do
 local expected=(r.id=='player-left' or r.id=='enemy-right') and L.margin or L.margin+L.ch+L.gap
 near(U.cardBounds(r,L).y,expected,'shuffled snapshot screen placement')
end
for i=3,4 do
 local r=copy(slots[i]);r.empty=true;r.hp=0
 near(U.cardBounds(r,L).y,U.cardBounds(slots[i],L).y,'empty/fainted slot does not collapse vertical identity')
end
yes(same(slots,original),'layout never mutates snapshot')
local ids={'player-left','player-right','enemy-left','enemy-right'}
local s={slots=slots,targets={{ids=ids,mode='selected'}}}
eq(U.defaultTargetIndex(s,ids),4,'default targets upper enemy card')
eq(U.defaultTargetIndex(s,{'enemy-left'}),1,'only lower enemy legal: use it')
eq(U.defaultTargetIndex(s,{'enemy-right'}),1,'only upper enemy legal: use it')
eq(U.defaultTargetIndex(s,{'player-right','player-left'}),2,'ally-only uses upper legal ally')
eq(U.defaultTargetIndex(s,{'enemy-right','enemy-left'}),1,'already ordered targets unchanged')
eq(U.defaultTargetIndex(s,{}),1,'empty legal target list safe')
local function nav(from,key,expected)
 local u={move={index=1},index=from}
 U.targetNavigate(s,u,{[key]=true})
 eq(ids[u.index],expected,'direction '..key..' from '..ids[from])
end
nav(1,'down','player-right');nav(2,'up','player-left')
nav(3,'up','enemy-right');nav(4,'down','enemy-left')
nav(1,'right','enemy-right');nav(2,'right','enemy-left')
nav(3,'left','player-right');nav(4,'left','player-left')
-- Narrow legal lists never introduce disallowed targets, even across columns.
s.targets[1].ids={'enemy-left','enemy-right'}
local u={move={index=1},index=1}
U.targetNavigate(s,u,{left=true});eq(u.index,1,'no fabricated ally target')
U.targetNavigate(s,u,{up=true});eq(u.index,2,'restricted enemy list follows visual up')
s.targets[1].ids={'enemy-left'};u.index=1
U.targetNavigate(s,u,{up=true});eq(u.index,1,'single legal target remains selected')

local graphics={}
for _,key in ipairs({'push','pop','origin','setShader','setScissor','setColor','setLineWidth','rectangle','line','setFont','print','polygon'}) do
 graphics[key]=function() end
end
graphics.getDimensions=function() return 1280,720 end
love={graphics=graphics}
local font={getWidth=function(_,str) return #str*6 end,getHeight=function() return 12 end}
for generation=1,2 do
 for _,serviceMode in ipairs({'combined','standalone'}) do
  local snapshot={battleId='hud-'..generation..'-'..serviceMode,ticket=42,turn=5,phase='command',
    commandSlot='player-left',battlerId='p1',nativeRules=generation,slots=copy(slots),party={},
    moves={{index=1,id='ICE_BEAM',name='ICE BEAM',type='ICE',pp=10,maxPP=10,enabled=true}},
    targets={{ids={'player-right','enemy-left','enemy-right'},mode='selected'}}}
  local before=copy(snapshot)
  local submitted,portraits,rings={},{},{}
  local api={version=1,snapshot=function() return snapshot end,submit=function(req)
    submitted[#submitted+1]=copy(req);return true
  end}
  local provider={exports={doubles=api}}
  local T={mod=serviceMode=='combined' and provider or {},font=function() return font end,
    plate=function() end,pod=function() end,podOverlay=function() end,
    portrait=function(_,mon,x,y,w,h)
      portraits[mon.species]={x=x,y=y,w=w,h=h};return true
    end}
  if serviceMode=='standalone' then T.findCBE=function() return provider end end
  local view=assert(loadfile(root..'/lib/DoublesUI.lua'))(T)
  eq(view._test.service(),api,'correct doubles provider')
  graphics.polygon=function(mode,...)
    if mode=='line' then rings[#rings+1]={...} end
  end
  local state=view._test.state(snapshot)
  view.input(api,snapshot,{a=true});eq(state.page,'moves','open move menu')
  view.input(api,snapshot,{a=true});eq(state.page,'targets','open target selector')
  eq(snapshot.targets[1].ids[state.index],'enemy-right','default targets the upper opponent')
  view.input(api,snapshot,{down=true})
  eq(snapshot.targets[1].ids[state.index],'enemy-left','down reaches lower opponent')
  view.input(api,snapshot,{up=true})
  eq(snapshot.targets[1].ids[state.index],'enemy-right','up chooses displayed upper opponent')
  yes(view.draw({},{}),'draw full doubles HUD')
  near(portraits.GOLBAT.y,L.margin+1.8*L.u,'Golbat portrait is upper')
  near(portraits.GENGAR.y,L.margin+L.ch+L.gap+1.8*L.u,'Gengar portrait is lower')
  near(portraits.ARTICUNO.y,L.margin+1.8*L.u,'player first portrait unchanged')
  near(portraits.BLASTOISE.y,L.margin+L.ch+L.gap+1.8*L.u,'player second portrait unchanged')
  eq(#rings,2,'one highlighted card with two ring strokes')
  near(rings[1][1][2],L.margin-2*L.u,'target ring follows upper opponent')
  view.input(api,snapshot,{a=true})
  local req=submitted[#submitted]
  eq(req.target,'enemy-right','confirmation submits correct original slot')
  eq(req.kind,'move','no command type change');eq(req.moveIndex,1,'move identity preserved')
  eq(req.slot,'player-left','command owner unchanged');eq(req.battlerId,'p1','actor identity preserved')
  eq(req.ticket,42,'ticket preserved');eq(req.turn,5,'turn preserved')
  view.input(api,snapshot,{down=true});view.input(api,snapshot,{a=true})
  eq(submitted[#submitted].target,'enemy-left','down and confirm select lower original slot')
  yes(same(snapshot,before),'drawing/navigation/submission never mutate authoritative state')
  -- Damage events use their subject's original slot; they must use the same
  -- mirrored screen mapping even when the other three cards are hidden.
  snapshot.phase='present'
  snapshot.presentation={kind='damage',slot='enemy-right',subject=copy(snapshot.slots[4]),
    battlerId='e2',previousHP=80,elapsed=.2,duration=.4,text='GOLBAT took damage.'}
  portraits={};rings={}
  yes(view.draw({},{}),'draw event-owned HUD')
  near(portraits.GOLBAT.y,L.margin+1.8*L.u,'damage subject retains upper opponent position')
  eq(portraits.GENGAR,nil,'unrelated opponent not forced into event HUD')
  eq(portraits.ARTICUNO,nil,'unrelated player not forced into event HUD')
  -- Replacement battlers inherit a slot, not a portrait/HP state from its old
  -- occupant. No data swapping is used to get the requested visual placement.
  local replacement=copy(snapshot.slots[3]);replacement.name='NEW';replacement.battlerId='replacement';replacement.hp=100
  eq(view.displayHP(replacement,{kind='move',impacts={snapshot.presentation}}),100,'replacement does not inherit another battler impact')
  near(view.cardBounds(replacement,L).y,L.margin+L.ch+L.gap,'replacement keeps original lower slot geometry')
 end
end
yes(same(slots,original),'original slot data preserved after every test')
print('DoublesOpponentHudOrderTests: '..count..' assertions passed')
