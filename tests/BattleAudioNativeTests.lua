-- ROM-free integration: actual Gen I/II kernels, reward queues, Sound and Music.
-- Sources/clock only are instrumented; run from the engine checkout.
package.path='./?.lua;./?/init.lua;'..package.path
local T=require('tests.modkit');local Data=T.fixtures.fresh()
require('src.render.Font').load(Data);require('src.battle.TypeChart').load(Data)
require('src.core.Logger').warn=function()end
local root=assert(os.getenv('CBE_DOUBLES_MOD_DIR'))
local function loadMod(p,v)return assert(loadfile(root..'/'..p))(v)end
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function eq(a,b,msg)checks=checks+1;assert(a==b,msg..': '..tostring(a)..' ~= '..tostring(b))end
local clock,creates,reads=0,0,0;local made={}
love.timer={getTime=function()return clock end}
love.filesystem.newFileData=function(bytes,name)return {bytes=bytes,name=name}end
love.audio={}
function love.audio.newSource(file,mode)
 creates=creates+1
 local name=type(file)=='table' and file.name or file
 local src={name=name,mode=mode,length=name=='victory.wav' and 5.2 or name=='level.wav' and 2 or name=='exp.wav' and .048 or mode=='stream' and 100 or .1,pitch=1,position=0}
 function src:play()self.on=true;self.started=clock;self.plays=(self.plays or 0)+1;return true end
 function src:stop()self.on=false;self.position=0 end
 function src:pause()self.position=self:tell();self.on=false end
 function src:isPlaying()return self.on==true and (self.loop or self:tell()<self.length)end
 function src:tell()return self.position+(self.on and clock-self.started or 0)end
 function src:getDuration()return self.length end
 function src:setLooping(v)self.loop=v end
 function src:setVolume(v)self.volume=v end
 function src:setFilter()end
 function src:setPitch(v)self.pitch=v end
 function src:getPitch()return self.pitch end
 function src:getChannelCount()return 2 end
 made[#made+1]=src;return src
end
local S=loadMod('lib/BattleAudioSpec.lua')
local function le(n,c)local t={};for i=1,c do t[i]=string.char(n%256);n=math.floor(n/256)end;return table.concat(t)end
local function wav(r)local raw=string.rep('\1\0\2\0',100);return 'RIFF'..le(36+#raw,4)..'WAVEfmt '..le(16,4)..le(1,2)..le(2,2)..le(r,4)..le(r*4,4)..le(4,2)..le(16,2)..'data'..le(#raw,4)..raw end
local cache={};for _,cue in ipairs(S.cues)do local w=wav(cue.rate);cache[cue.path]=w;cache[S.markerPath(cue)]=S.marker(cue,w)end
local Sound=require('src.core.Sound');local Music=require('src.core.Music')
local Events=require('src.mods.Events').new();local Hooks=require('src.mods.Hooks').new()
require('src.mods.Runtime').install(Events,Hooks,{})
local Stack=require('src.core.StateStack')
local function game(data,save)
 return {data=data,save=save,stack=setmetatable({states={}},{__index=Stack}),input={wasPressed=function()return true end,isDown=function()return false end},logicSpeed=function()return 1 end}
end
local function soundData(data)
 data.audio=data.audio or {};data.audio.sfx={}
 for _,name in ipairs({'Level_Up','Sfx_DexFanfare5079','Sfx_ExpBar','Sfx_HitEndOfExpBar','Sfx_SwitchPokemon'})do data.audio.sfx[name]={file='native-'..name..'.wav'}end
 data.audio.songs={BATTLE={file='battle.wav'},WIN={file='native-win.wav'},MAP={file='map.wav'}}
 data.audio.battle={trainer='BATTLE',trainerWin='WIN',wild='BATTLE',wildWin='WIN'}
end
soundData(Data)
local Save=require('src.core.SaveData');local Pokemon=require('src.pokemon.Pokemon')
local Battle1=require('src.battle.BattleState')
local save=Save.newGame();save.party={Pokemon.new(Data,'FIXMON_A',25),Pokemon.new(Data,'FIXMON_B',25)};save.options.textSpeed=1
local g=game(Data,save);local b=Battle1.newTrainer(g,'OPP_FIX_YOUNGSTER',1);g.stack.states={b}
local mod={id='COLOSSEUM_OVERHAUL',game=g,hooks={wrap=function(_,n,fn,p)return Hooks:wrap(n,fn,p,'audio-test')end},
 events={on=function(_,n,fn,p)return Events:on(n,fn,p,'audio-test')end,
 emit=function(_,n,e)check(n:find('mod.COLOSSEUM_OVERHAUL.',1,true)==1,'public events respect mod namespace');return Events:emit(n,e)end}}
local A=loadMod('lib/BattleAudio.lua',{mod=mod,engineRequire=require,BattleAudioSpec=S,GeneratedAssets={read=function(p)reads=reads+1;return cache[p]end}})
check(A.install(mod),'runtime installs against real engine');eq(creates,4,'four preloaded sources')
Music.play(Data,'BATTLE',true,{reason='battle'})
local bgm=made[#made];check(bgm:isPlaying(),'native BGM playing before fanfare')
local level=Sound.play(Data,'Level_Up');check(level and level:isPlaying(),'native Sound call returns playing level ticket')
check(not bgm:isPlaying(),'native Music pauses selected BGM')
local createsBefore,readsBefore=creates,reads
clock=2.1;Music.update(Data);check(bgm:isPlaying(),'native Music resumes same Source')
Music.playVictory(Data,'trainer');eq(Music.current(),'BATTLE','victory does not replace retained BGM label');check(not bgm:isPlaying(),'victory ducks BGM')
local queued=Sound.play(Data,'Level_Up');check(Sound.waitFrames(queued)>7*60,'native timeout includes queued victory')
clock=7.4;Music.update(Data);check(queued:isPlaying() and not bgm:isPlaying(),'native queue hands off victory to level')
clock=9.5;Music.update(Data);check(not queued:isPlaying() and bgm:isPlaying(),'native music resumes once queue empties')
eq(creates,createsBefore,'no audio creation during native triggers');eq(reads,readsBefore,'no cache reads during native triggers')
-- Native Gen1 award math/participant ownership is untouched. Compare a separate
-- control battle using the same data and party, then execute the real text queue.
local function fixture1(enabled)
 local sv=Save.newGame();sv.party={Pokemon.new(Data,'FIXMON_A',25),Pokemon.new(Data,'FIXMON_B',25)};sv.options.textSpeed=1
 sv.colosseumBattle={battleSoundsEnabled=enabled}
 local gm=game(Data,sv);local st=Battle1.newTrainer(gm,'OPP_FIX_YOUNGSTER',1);gm.stack.states={st}
 A.attachGame(gm);st.queue={};st.current=nil;st.nextInsert=0;st.participants={[st.player.mon]=true}
 local before=st.player.mon.exp;st:awardExp()
 return gm,st,st.player.mon.exp-before
end
local cg,control,deltaControl=fixture1(false)
local ng,nb,deltaNew=fixture1(true)
eq(deltaNew,deltaControl,'native Gen1 awarded EXP unchanged')
eq(#nb.queue,#control.queue,'native Gen1 reward queue length unchanged')
local start=A.status().totals.exp
nb:updateQueue();eq(A.status().totals.exp,start+1,'native Gen1 GainedText starts cue at display, not award calculation')
clock=clock+.7;Music.update(Data);check(not A.status().expPlaying,'Gen1 cue terminates while native text may remain')
-- Free-slot learnMove owns the success event and jingle; calling it again does
-- not learn or play twice. Execute real queue closures without replacing them.
nb.queue={};nb.current=nil;nb.nextInsert=0;nb.waitFrames=nil;nb.waitingSound=nil
nb.player.mon.moves={}
local move=next(Data.moves);check(move~=nil,'fixture move exists')
nb:learnMove(nb.player.mon,move)
local learntBefore=A.status().totals.level
for i=1,500 do
 clock=clock+1/60;Music.update(Data)
 nb:updateQueue()
 if A.status().totals.level>learntBefore then break end
end
eq(A.status().totals.level,learntBefore+1,'native Gen1 learned-move success plays source fanfare')
local size=#nb.queue;nb:learnMove(nb.player.mon,move);eq(#nb.queue,size,'duplicate known move adds no cue')
Sound.stop('Level_Up');Music.update(Data)
-- Gold actual kernel and battle view: native EXP bar owns start/stop and repeats
-- cleanly across level boundaries. Its success/decline forget paths are native.
local f=dofile(root..'/tests/doubles/fixture_gen2.lua');local D=f.data;soundData(D)
local M=f.Mon;local Kernel=require('src.battle.gen2.Battle');local View=require('src.ui.gen2.BattleState')
local party={M.new(D,'CYNDAQUIL',25),M.new(D,'PIDGEY',25)}
local sv={party=party,player={id=1,name='TEST'},badges={},kantoBadges={},options={sfxVol=7,textSpeed=1},pokedex={seen={},owned={}},colosseumBattle={battleSoundsEnabled=true}}
local host=Kernel.new{data=D,party=party,trainer={name='TEST',party={M.new(D,'PIDGEY',10)},baseMoney=20},random=function()return 0 end,save=sv}
local gg=game(D,sv);local screen=View.new(gg,{battle=host});gg.stack.states={screen};A.attachGame(gg)
screen.queue={};screen.phase='menu';screen.slideFrame=100
local beforeExp=party[1].experience
host:awardExperience(host.enemy);local events=host:takeEvents()
check(party[1].experience>beforeExp,'native Gold award committed')
local award
for _,event in ipairs(events)do if event.kind=='experience' and event.index==1 then award=event end end
check(award~=nil,'native Gold experience event exists')
screen.queue={award};screen:advanceQueue();check(screen.expAnim~=nil,'native Gold display starts EXP animation')
local beforeLoop=A.status().totals.exp
local saw=false
for i=1,1000 do clock=clock+1/60;Music.update(D);screen:stepExpAnim();saw=saw or A.status().expPlaying;if not screen.expAnim then break end end
check(saw,'native Gold EXP animation uses original Colosseum loop')
check(screen.expAnim==nil and not A.status().expPlaying,'native Gold bar completes and stops loop')
eq(A.status().totals.exp,beforeLoop+1,'one start for one native EXP segment')
-- Force a DISPLAY-only two-level catch-up, not an extra award. Native renderer
-- follows the already committed mon; no reward calculation is replaced.
screen.shownLevel=party[1].level-2;screen.shownExp=60;screen.expAnim={mon=party[1],frames=3,wait=0,pixels=0};screen.waitSfx=nil
local beforeLevel=A.status().totals.level
for i=1,2500 do
 clock=clock+1/60;Music.update(D)
 if screen.waitSfx then if not Sound.isPlaying(screen.waitSfx)then screen.waitSfx=nil end
 else screen:stepExpAnim()end
 if not screen.expAnim then break end
end
check(screen.expAnim==nil,'native multi-level EXP renderer finishes')
eq(A.status().totals.level,beforeLevel+2,'one source fanfare for each displayed level crossing')
-- Real full-slot success: native event queue contains the success fanfare only
-- after commit. Declining has no success sfx.
party[1].moves={{id='TACKLE',pp=20},{id='EMBER',pp=20},{id='SPORE',pp=20},{id='BIDE',pp=20}}
host.events={};check(host:resolveForget(1,2,{id='WATER_GUN',pp=25},'WATER GUN'),'native full-slot move change succeeds')
local nativeEvents=host:takeEvents();local success
for _,e in ipairs(nativeEvents)do if e.sfx=='Sfx_DexFanfare5079'then success=e end end
check(success~=nil,'native successful learn queues correct fanfare')
screen.queue={success};local prev=A.status().totals.level;screen:advanceQueue();eq(A.status().totals.level,prev+1,'native Gold learned success emits once')
Sound.stop('Sfx_DexFanfare5079');Music.update(D)
host:declineForget(1,'EMBER');for _,e in ipairs(host:takeEvents())do check(e.sfx~='Sfx_DexFanfare5079','declining never celebrates')end
-- Pop while playing: no stuck EXP or jingle, native MAP retains ownership.
Sound.play(D,'Sfx_ExpBar');gg.stack.states={};Music.update(D);check(not A.status().expPlaying,'battle pop kills EXP loop')
Music.play(D,'MAP',true,{reason='map'});eq(Music.current(),'MAP','map transition remains native')
print('BattleAudioNativeTests: '..checks..' assertions passed')
