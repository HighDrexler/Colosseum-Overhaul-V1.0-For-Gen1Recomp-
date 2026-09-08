-- Screen-space layout contracts. Separate optional LÖVE captures exercise the
-- native Gen I/II render pipelines; this suite does not claim a real GPU.
local checks=0;local function yes(v,m)checks=checks+1;assert(v,m)end
local draws={};local f;local width,height
love={graphics={push=function()end,pop=function()end,origin=function()end,setShader=function()end,
 setColor=function()end,setLineWidth=function()end,setScissor=function()end,setBlendMode=function()end,
 rectangle=function(mode,x,y,w,h)yes(w>=0 and h>=0,'nonnegative rectangle')end,
 newFont=function(size)return {size=size,setFilter=function()end,getHeight=function()return size end,
  getWidth=function(_,s)local n=0;for _ in tostring(s):gmatch('[%z\1-\127\194-\244][\128-\191]*')do n=n+1 end;return n*size*.55 end}end,
 setFont=function(v)f=v end,print=function(t,x,y)
  local d={x=x,y=y,w=f:getWidth(t),h=f:getHeight(),text=t};draws[#draws+1]=d
  yes(d.x>=0 and d.y>=0 and d.x+d.w<=width+1 and d.y+d.h<=height+1,'text bounded: '..t)
 end}}
local S=assert(loadfile('lib/CacheScreen.lua'))()
for _,size in ipairs{{320,240},{640,360},{400,800},{800,400},{1168,980},{1920,1080}}do
 width,height=size[1],size[2]
 for _,mode in ipairs{'choice','reuse-choice','continue-choice','continue-reuse','new-choice','new-reuse','planning','quick','error','complete','full','battle'}do
  local s={game={data={pokemon={}}},rows={},index=14,choice=1,mode='quick',startedAt=0,
   label='Preparing source geometry / a_long_native_animation_name'}
  for i=1,30 do s.rows[i]={dex=i,variant='normal'}end
  s.selector=mode=='choice' or mode=='reuse-choice' or mode=='continue-choice' or mode=='continue-reuse' or mode=='new-choice' or mode=='new-reuse';
  if mode=='continue-choice' or mode=='continue-reuse' or mode=='new-choice' or mode=='new-reuse' then s.startupRequest={newGame=mode=='new-choice' or mode=='new-reuse'} end
  if mode=='reuse-choice' or mode=='continue-reuse' or mode=='new-reuse' then s.reuseChecked=true;s.reuseEligible=true;s.reuseInfo={cachedModels=30} end
  if s.selector and s.reuseChecked==nil then s.reuseChecked=true end
  s.planning=mode=='planning';s.complete=mode=='complete'
  s.full=mode=='full';s.battle=mode=='battle'
  if s.complete then s.index=31 end
  s.batchInfo={cachedModels=43,cachedAppearances=81}
  if mode=='error'then s.error=string.rep('long error / ',80)end
  draws={};S.draw(s,width,height,s.batchInfo,123)
  for i,b in ipairs(s.buttons)do
   yes(b.x>=0 and b.y>=0 and b.x+b.w<=width and b.y+b.h<=height,'button bounds')
   for j=1,i-1 do local a=s.buttons[j];yes(b.x>=a.x+a.w or a.x>=b.x+b.w or b.y>=a.y+a.h or a.y>=b.y+b.h,'button hitboxes do not overlap')end
  end
  for i,d in ipairs(draws)do
   for j=1,i-1 do local a=draws[j]
    yes(d.x+d.w<=a.x or a.x+a.w<=d.x or d.y+d.h<=a.y+1 or a.y+a.h<=d.y+1,'text lines do not overlap: '..d.text..' / '..a.text)
   end
  end
 end
end
-- A reusable cache is a real top-level action, not merely explanatory text.
width,height=800,400;draws={}
local reuse={game={data={pokemon={}}},rows={},index=1,choice=1,mode='choice',selector=true,
 startupRequest={newGame=false},reuseChecked=true,reuseEligible=true,reuseInfo={cachedModels=30},startedAt=0}
S.draw(reuse,width,height,nil,1)
yes(reuse.buttons[1] and reuse.buttons[1].key=='reuse','REUSE CACHE is the first actionable row')
local saw=false;for _,d in ipairs(draws)do if d.text=='REUSE CACHE'then saw=true;break end end
yes(saw,'REUSE CACHE label rendered')
-- While reuse eligibility is still being checked, do not flash QUICK START or
-- CURRENT TEAM as a selectable-looking default before REUSE can replace it.
width,height=800,400;draws={}
local checking={game={data={pokemon={}}},rows={},index=1,choice=1,mode='choice',selector=true,
 startupRequest={newGame=false},reuseChecked=false,reuseEligible=false,startedAt=0}
S.draw(checking,width,height,nil,1)
yes(checking.buttons[1] and checking.buttons[1].key=='wait','read-only cache probe uses a non-action checking row')
local sawChecking,sawQuick,sawTeam=false,false,false
for _,d in ipairs(draws)do
 if d.text=='CHECKING SAVED CACHE'then sawChecking=true end
 if d.text=='QUICK START / 30 NEW'then sawQuick=true end
 if d.text=='CURRENT TEAM ONLY'then sawTeam=true end
end
yes(sawChecking,'cache probe status is explicit')
yes(not sawQuick and not sawTeam,'action rows stay hidden until reuse eligibility is known')

-- Native draw paths intentionally do not put RGB glyphs into GB palette space.
local V={WorkBudget={},PokemonActors={}}
local C=assert(loadfile('lib/BattleCache.lua'))(V)
local State=C._test.State;draws={};State.draw({});State.drawWidescreen({},1280,720)
yes(#draws==0,'no low-resolution/palette text pass')
print('CacheScreenLayoutTests: '..checks..' checks PASS; six viewport sizes, selector/progress/errors/completion, bounded hitboxes and no overlapping text')
