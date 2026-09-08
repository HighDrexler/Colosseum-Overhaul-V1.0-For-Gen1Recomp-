-- Requires the engine checkout's ROM-free tests.modkit fixtures. Run from that
-- checkout with UI_COMPAT_DIR pointing to this unpacked mod. Graphics are
-- instrumented fixtures, NOT a live LOVE renderer or a gameplay screenshot.
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit')
local Data=T.fixtures.fresh()
local EngineFont=require('src.render.Font');EngineFont.load(Data)
require('src.battle.TypeChart').load(Data)
require('src.core.Logger').warn=function() end
local root=assert(os.getenv('UI_COMPAT_DIR'),'UI_COMPAT_DIR is required')
local f=assert(io.open(root..'/UIMain.lua','rb'));local source=f:read('*a');f:close()
local cut=assert(source:find('\nreturn function(mod)',1,true))
-- Load the ENTIRE shipped implementation, exposing internals only in memory.
-- Do not substitute a corrected choice renderer in the baseline control.
local api=assert(loadstring(source:sub(1,cut-1)..[[
return {G=GoldCompat,S=State,render=renderHudHook,
 setMod=function(m) modRef=m;GoldCompat.game=m.game;GoldCompat.invalidateOptionValue(nil) end}
]],'@SingleBattleSwitch/shipped-UIMain'))()
local G,S=api.G,api.S
local checks=0
local function yes(v,msg) checks=checks+1;assert(v,msg) end
local function eq(a,b,msg) checks=checks+1;assert(a==b,msg..': '..tostring(a)..' ~= '..tostring(b)) end
local g=love.graphics
local width,height=1280,720
local texts,rects,errors={},{},{}
local function font(size)
 local q={size=size}
 function q:getHeight()return self.size end
 function q:getWidth(s)return #tostring(s)*self.size*.55 end
 function q:setFilter()end
 function q:getWrap(s,w)
  local rows={};local n=math.max(1,math.floor(w/(self.size*.55)))
  for line in (tostring(s)..'\n'):gmatch('(.-)\n')do
   if line=='' then rows[#rows+1]='' else
    while #line>n do rows[#rows+1]=line:sub(1,n);line=line:sub(n+1)end
    rows[#rows+1]=line
   end
  end
  return math.min(self:getWidth(s),w),rows
 end
 return q
end
local gs={font=font(12),color={1,1,1,1},scissor={},sx=1,sy=1,tx=0,ty=0}
local frames={}
local function copy(s)local t={};for k,v in pairs(s)do t[k]=v end;return t end
function g.getDimensions()return width,height end
function g.getWidth()return width end
function g.getHeight()return height end
function g.newFont(a,b)return font(type(a)=='number' and a or b or 12)end
function g.setFont(v)gs.font=v end
function g.getFont()return gs.font end
function g.push()frames[#frames+1]=copy(gs)end
function g.pop()assert(#frames>0,'graphics stack underflow');gs=table.remove(frames)end
function g.getStackDepth()return #frames end
function g.origin()gs.sx=1;gs.sy=1;gs.tx=0;gs.ty=0 end
function g.translate(x,y)gs.tx=gs.tx+x*gs.sx;gs.ty=gs.ty+y*gs.sy end
function g.scale(x,y)gs.sx=gs.sx*x;gs.sy=gs.sy*(y or x)end
function g.setScissor(...)gs.scissor={...}end
function g.getScissor()return unpack(gs.scissor)end
function g.setColor(...)local a={...};gs.color=type(a[1])=='table' and a[1] or a end
function g.getColor()return unpack(gs.color)end
function g.rectangle(mode,x,y,w,h)rects[#rects+1]={mode,x*gs.sx+gs.tx,y*gs.sy+gs.ty,w*gs.sx,h*gs.sy}end
function g.print(s,x,y)texts[#texts+1]={tostring(s),x or 0,y or 0}end
function g.printf(s,x,y,...)g.print(s,x,y)end
function g.polygon()end
function g.line()end
function g.circle()end
function g.setLineWidth()end
function g.getLineWidth()return 1 end
function g.setLineStyle()end
function g.setShader()end
function g.getShader()end
local function contains(s)for _,t in ipairs(texts)do if t[1]:find(s,1,true)then return true end end;return false end
local function clearDraw()texts={};rects={};errors={}end
local options={hideNativeBattleUI=false,colosseumBattleUI=true,revampedDialogueBoxes=true,mobileBattleUI=false}
local mod={options={get=function(_,k)return options[k]end}}
mod.log=setmetatable({info=function()end},{__call=function(_,level,msg)errors[#errors+1]=msg end})
local SaveData=require('src.core.SaveData');local Pokemon=require('src.pokemon.Pokemon')
local Battle=require('src.battle.BattleState');local Choice=require('src.ui.ChoiceBox')
local Party=require('src.ui.PartyMenu');local TextBox=require('src.render.TextBox')
local Stack=require('src.core.StateStack')
local Runtime=require('src.mods.Runtime');local Hooks=require('src.mods.Hooks')
local nativeChoiceDraw=Choice.draw
local hooks=Hooks.new()
hooks:wrap('battle.bottom_ui_visible',function(next,state)
 if G.ownsNativeBattleLayer(state) then return false end
 return next(state)
end,12000,'switch-test-exact-ui-contract')
Runtime.install(require('src.mods.Events').new(),hooks,{})
local function fixture(style,dead)
 local save=SaveData.newGame();save.player.name='RED'
 save.party={Pokemon.new(Data,'FIXMON_A',30),Pokemon.new(Data,'FIXMON_B',30),Pokemon.new(Data,'FIXMON_A',30)}
 save.options.battleStyle=style or 'shift';save.options.textSpeed=1
 local game={data=Data,save=save,stack=setmetatable({states={}},{__index=Stack}),
  input={pressed={},wasPressed=function(self,k)return self.pressed[k] or false end,isDown=function()return false end}}
 mod.game=game;api.setMod(mod)
 local b=Battle.newTrainer(game,'OPP_FIX_YOUNGSTER',1);game.stack.states={b}
 if dead then b.player.mon.hp=0 end
 b.participants={};b.enemyParty[1].hp=0;b.enemy.mon=b.enemyParty[1];b:enemyMonFainted()
 S.activeBattle=nil;S.activeChoiceBox=nil;S.activeDialogueBox=nil
 return game,b
end
local function press(game,key)
 game.input.pressed={[key]=true};game.stack:update(1/60);game.input.pressed={}
end
local function openChoice(game,b)
 local row,at
 for i,r in ipairs(b.queue)do if r.choice then row=r;at=i;break end end
 local tail={};if at then for i=at+1,#b.queue do tail[#tail+1]=b.queue[i]end end
 yes(row~=nil,'native SHIFT queues the real choice')
 b.queue={};b:startMessage(row);b.phase='messages';b.waitFrames=nil
 for i=1,1000 do b:updateQueue();if getmetatable(game.stack:top())==Choice then break end end
 local c=game.stack:top();yes(getmetatable(c)==Choice,'native queue constructs ChoiceBox')
 b.queue=tail;b.afterQueue='menu'
 return c
end
local function settleChoice(game,c,key)
 press(game,key)
 for i=1,60 do if game.stack:top()~=c then break end;game.stack:update(1/60)end
 yes(game.stack:top()~=c,'native pending/hold dispatches one choice')
end
local game,b=fixture();api.setMod(mod)
S.Installers.installOverworldUI(mod);S.Installers.installDialogueThemeDirect(mod)
local dimensions={{1280,720},{1227,1008},{1920,1080},{720,1280},{390,844}}
for _,dims in ipairs(dimensions)do
 width,height=dims[1],dims[2]
 for _,mobile in ipairs({false,true})do
  for _,dialogue in ipairs({true,false})do
   options.mobileBattleUI=mobile;options.revampedDialogueBoxes=dialogue;G.invalidateOptionValue(nil)
   game,b=fixture();local c=openChoice(game,b)
   clearDraw();nativeChoiceDraw(c)
   eq(#texts,0,'native ChoiceBox really is hidden by the battle hook')
   clearDraw()
   -- A previous battle was last drawn: must recover the real owner from stack.
   S.activeBattle={game=game,phase='messages',current={text='STALE PROMPT'}}
   local before=c.onChoose
   yes(G.renderHudDialogueLayer(mod,game),'battle choice owns final frame')
   eq(#errors,0,'normal choice must not take an exception/fallback: '..table.concat(errors,'; '))
   yes(contains('YES') and contains('NO'),'both native choice labels are visible')
   yes(contains('Will RED') and contains('change POK'),'actual native switch question remains visible')
   yes(not contains('STALE PROMPT'),'no previous encounter prompt')
   eq(c.onChoose,before,'render never replaces the choice callback')
   eq(c.index,1,'render never changes native selection')
   eq(c.pending,nil,'render never submits an answer')
   eq(g.getStackDepth(),0,'normal prompt leaves graphics stack balanced')
  end
 end
end
width,height=1280,720;options.mobileBattleUI=false;options.revampedDialogueBoxes=true;G.invalidateOptionValue(nil)
-- Fail-visible fallback, including a nested renderer that throws after push.
for _,mode in ipairs({'throw','false','prompt'})do
 game,b=fixture();local c=openChoice(game,b)
 local drawChoice,drawPrompt=G.drawChoiceThemeFinal,G.ColosseumUI.drawDialogue
 if mode=='prompt' then G.ColosseumUI.drawDialogue=function()return false end
 elseif mode=='false' then G.drawChoiceThemeFinal=function()return false end
 else G.drawChoiceThemeFinal=function()g.push('all');g.translate(91,27);g.setScissor(0,0,0,0);error('injected renderer failure')end end
 clearDraw();g.setScissor(2,3,4,5);local oldFont=g.getFont()
 yes(G.renderHudDialogueLayer(mod,game),'failed renderer uses a visible fallback')
 yes(contains('YES') and contains('NO') and contains('change POK'),'fallback includes choice and exact prompt')
 eq(g.getStackDepth(),0,'exception restores all nested graphics pushes')
 eq(g.getScissor(),2,'exception restores caller scissor');eq(g.getFont(),oldFont,'exception restores caller font')
 eq(c.pending,nil,'fallback never submits');eq(c.index,1,'fallback keeps real cursor')
 g.setScissor();G.drawChoiceThemeFinal=drawChoice;G.ColosseumUI.drawDialogue=drawPrompt
end
-- NO, B, and YES -> party -> B use the real engine callbacks and installed UI.
for _,mode in ipairs({'no','b','party-b','switch','same','fainted'})do
 game,b=fixture();local current=b.player.mon;local c=openChoice(game,b)
 if mode=='no' then press(game,'down');eq(c.index,2,'native down chooses NO');settleChoice(game,c,'a')
 elseif mode=='b' then settleChoice(game,c,'b')
 else
  settleChoice(game,c,'a');local p=game.stack:top()
  yes(getmetatable(p)==Party,'YES opens full native party picker')
  eq(p.forceSwitch,true,'SHIFT direct-pick flag is preserved, not misread as compulsory')
  yes(p.__gen3uiColosseumParty,'picker retains custom party presentation')
  if mode=='switch' then
   p.index=2;press(game,'a');eq(game.stack:top(),b,'valid switch closes picker')
  elseif mode=='same' or mode=='fainted' then
   if mode=='fainted' then p.index=2;p.party[2].hp=0 else p.index=1 end
   press(game,'a');yes(getmetatable(game.stack:top())==TextBox,'invalid selection uses real refusal TextBox')
   -- Finish the real text before dismissing it; it must return to the picker.
   for i=1,1000 do
    if game.stack:top()==p then break end
    game.input.pressed={a=true};game.stack:update(1/60);game.input.pressed={}
   end
   eq(game.stack:top(),p,'native refusal returns to same picker')
   press(game,'b');eq(game.stack:top(),b,'refused selection still permits B cancel')
  else press(game,'b');eq(game.stack:top(),b,'B exits optional SHIFT party without a switch')end
 end
 eq(b.player.mon,current,'choice/cancel does not directly replace active mon before queued sendout')
 eq(game.stack:top(),b,'choice flow returns control to the same battle')
 -- Execute the preserved native queue after the choice; do not merely inspect
 -- a mocked onSwitch callback. This includes enemy send-out/player switch acts.
 for i=1,20000 do
  if game.stack:top()==b and b.phase=='menu' then break end
  game.input.pressed={a=true};game.stack:update(1/60);game.input.pressed={}
 end
 eq(b.phase,'menu','native sendout queue reaches command menu after '..mode)
 eq(game.stack:top(),b,'no party re-open after optional choice '..mode)
 eq(b.player.mon,mode=='switch' and game.save.party[2] or current,
  'only explicit valid selection replaces active Pokemon: '..mode)
end
-- Genuine faint replacement remains compulsory. B may dismiss a native picker,
-- but the real battle guard reopens it until a living Pokemon is selected.
game,b=fixture();b.queue={};b.current=nil;b.waitFrames=nil;b.phase='menu';b.player.mon.hp=0
for round=1,2 do
 for i=1,20 do if getmetatable(game.stack:top())==Party then break end;game.stack:update(1/60)end
 yes(getmetatable(game.stack:top())==Party,'fainted active requires a native replacement')
 press(game,'b');eq(game.stack:top(),b,'B returns to native replacement guard')
end
-- SET and a fainted active Pokemon do not acquire an optional SHIFT offer.
for _,case in ipairs({{'set',false},{'shift',true}})do
 game,b=fixture(case[1],case[2]);local count=0
 for _,r in ipairs(b.queue)do if r.choice then count=count+1 end end
 eq(count,0,'native SET/fainted-active excludes optional SHIFT')
end
-- Field dialogue OFF remains OFF; the fix does not write/change user settings.
options.revampedDialogueBoxes=false;options.hideNativeBattleUI=false;G.invalidateOptionValue(nil)
local field={game={stack={states={}}}}
eq(G.dialoguePresentationEnabled(field),false,'field dialogue setting remains independent')
-- API wrappers with masked metatables still recognize the precise battle choice.
game,b=fixture();local c=openChoice(game,b);local proxy={}
for k,v in pairs(c)do proxy[k]=v end
setmetatable(proxy,{__metatable='api-wrapper'})
yes(G.isDialogueChoiceState(proxy,b),'stack-owned battle choice works with opaque proxy metatable')
yes(not G.isDialogueChoiceState(proxy,{game=game}),'unrelated menu is not adopted as a choice')
-- Covered cached choice does not steal a party frame.
game.stack.states={b,c,{game=game}};S.activeChoiceBox=c
clearDraw();eq(G.renderHudDialogueLayer(mod,game),false,'covered choice yields foreground');eq(#texts,0,'covered choice does not paint')
Runtime.reset()
print('SingleBattleSwitchUITests: '..checks..' assertions passed (real engine queue/ChoiceBox/PartyMenu; instrumented graphics)')
