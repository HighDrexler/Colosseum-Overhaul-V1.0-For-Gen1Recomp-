local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local function loadMod(p,v)return assert(loadfile(root..'/'..p))(v)end
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function eq(a,b,msg)checks=checks+1;assert(a==b,msg..': '..tostring(a)..' ~= '..tostring(b))end
local S=loadMod('lib/BattleAudioSpec.lua')
local function le(n,c)local out={};for i=1,c do out[i]=string.char(n%256);n=math.floor(n/256)end;return table.concat(out)end
local function wav(r)local b=string.rep('\1\0\2\0',100);return 'RIFF'..le(36+#b,4)..'WAVEfmt '..le(16,4)..le(1,2)..le(2,2)..le(r,4)..le(r*4,4)..le(4,2)..le(16,2)..'data'..le(#b,4)..b end
local cache={};for _,c in ipairs(S.cues)do cache[c.path]=wav(c.rate);cache[S.markerPath(c)]=S.marker(c,cache[c.path])end
local clock,reads,creates,fdCalls=0,0,0,0
local made={}
love={timer={getTime=function()return clock end},filesystem={newFileData=function(b,name)fdCalls=fdCalls+1;return{bytes=b,name=name}end},audio={}}
function love.audio.newSource(fd,mode)
 eq(mode,'static','predecoded static cue');creates=creates+1
 local src={name=fd.name,duration=fd.name=='victory.wav' and 5.2 or fd.name=='level.wav' and 2.0 or .048,volume=1}
 function src:setLooping(v)self.loop=v end
 function src:setVolume(v)self.volume=v end
 function src:play()self.start=clock;self.on=true;self.plays=(self.plays or 0)+1;return true end
 function src:stop()self.on=false end
 function src:isPlaying()return self.on==true and (self.loop or clock-self.start<self.duration)end
 function src:getDuration()return self.duration end
 function src:tell()return self.start and math.min(self.duration,clock-self.start) or 0 end
 function src:getPitch()return 1 end
 made[#made+1]=src;return src
end
local events={listeners={}}
function events:on(n,fn)self.listeners[n]=fn end
function events:emit(n,e)if self.listeners[n]then self.listeners[n](e)end end
local hooks={handlers={}}
function hooks:wrap(n,fn,priority)self.handlers[n]=fn end
local game={save={options={sfxVol=7},colosseumBattle={}},stack={states={}}}
local nativePlays,nativeStops,nativeUpdates={},0,0
local Sound={}
function Sound.play(_,n)nativePlays[#nativePlays+1]=n;return 'native:'..n end
function Sound.isPlaying(n)return n=='native-live'end
function Sound.stop()nativeStops=nativeStops+1 end
function Sound.waitFrames(src,fallback)return math.ceil(src:getDuration()*60)+2 end
function Sound.waitFramesFor()return 99 end
function Sound.sfxBusy()return false end
function Sound.sfxRemaining()return 0 end
function Sound.waitSfxDone()end
function Sound.sfxChannelsOff()end
function Sound.setVolumeLevel()end
local Music={song='BATTLE'}
function Music.duckForFanfare(t)Music.fanfare=t;Music.paused=true end
function Music.update()
 nativeUpdates=nativeUpdates+1
 if Music.fanfare and not Music.fanfare:isPlaying()then Music.fanfare=nil;Music.paused=false;Music.resumes=(Music.resumes or 0)+1 end
end
local C1={isBattleState=true}
function C1:sayNext(text)self.nextInsert=(self.nextInsert or 0)+1;table.insert(self.queue,self.nextInsert,{text=text})end
function C1:updateQueue()self.current=table.remove(self.queue,1);return 'native-update',nil end
local C2={}
function C2:pic()end
function C2:activeMon()return self.battle.player end
function C2:advanceQueue()
 local e=table.remove(self.queue,1);self.last=e
 if e and e.kind=='experience' and self.battle.party[e.index]==self.battle.player then self.expAnim={}end
 return 'native-gold-update'
end
local modules={['src.core.Sound']=Sound,['src.core.Music']=Music,['src.battle.BattleState']=C1,['src.ui.gen2.BattleState']=C2}
local mod={game=game,hooks=hooks,events=events}
local V={mod=mod,BattleAudioSpec=S,GeneratedAssets={read=function(path)reads=reads+1;return cache[path]end},engineRequire=function(p)return assert(modules[p],p)end}
local A=loadMod('lib/BattleAudio.lua',V)
check(A.install(mod),'installs');eq(creates,4,'only four static sources');eq(fdCalls,3,'three decoded files, shared EXP data')
for _,src in ipairs(made)do eq(src.volume,.8*(src.name=='exp.wav' and .75 or 1),'full-volume EXP reduced once; jingles unchanged')end
local startReads,startCreates=reads,creates
check(A.install(mod),'idempotent install');eq(creates,4,'idempotent source load')
eq(Sound.play({},'Level_Up'),'native:Level_Up','overworld fanfare unaffected')
local b=setmetatable({game=game,queue={},player={mon={hp=10}},kind='trainer'},{__index=C1});game.stack.states={b}
local t=Sound.play({},'Level_Up');check(type(t)=='table' and t:isPlaying(),'Gen1 level source/ticket returned')
check(Music.paused,'fanfare ducks, not master volume');eq(Sound.waitFramesFor('Level_Up'),122,'native duration polling uses two-second source')
check(Sound.isPlaying('Sfx_DexFanfare5079'),'shared native level aliases resolve')
clock=2.1;Music.update();check(not t:isPlaying() and not Music.paused,'native music resumes after level')
eq(Music.song,'BATTLE','selected BGM identity unchanged')
local learned=Sound.play({},'Level_Up');eq(A.status().totals.level,2,'successful learned-move fanfare may repeat at a distinct success')
clock=4.2;Music.update()
local before=A.status().totals.victory
local function selected(song)return song end
local out=hooks.handlers['music.select'](selected,'NATIVE_WIN',{reason='victory'})
eq(out,nil,'win suppresses native looping victory track only when own cue available')
eq(A.status().totals.victory,before+1,'win plays once')
eq(hooks.handlers['music.select'](selected,'NATIVE_WIN',{reason='victory'}),nil,'repeat selection does not restart')
eq(A.status().totals.victory,before+1,'dedupe per encounter')
local pending=Sound.play({},'Level_Up');check(pending:isPlaying(),'level queues behind victory rather than disappearing')
check(pending:getDuration()>7,'queued wait covers victory + level')
eq(A.status().pendingFanfares,1,'one pending jingle')
clock=9.5;Music.update();check(pending:isPlaying() and Music.paused,'queued level starts without music-resume blip')
clock=11.6;Music.update();check(not pending:isPlaying() and not Music.paused,'queue releases native duck')
local exp=Sound.play({},'Sfx_ExpBar');check(exp:isPlaying() and exp.loop,'Gen2 EXP loops only its source-authored cycle')
Sound.stop('Sfx_ExpBar');check(not exp:isPlaying(),'native stop immediately stops EXP')
local endPulse=Sound.play({},'Sfx_HitEndOfExpBar');check(endPulse:isPlaying() and not endPulse.loop,'bar end is bounded single pulse')
clock=11.7;Music.update();check(not Sound.isPlaying('Sfx_HitEndOfExpBar'),'end wait resolves')
Sound.setVolumeLevel(0);for _,src in ipairs(made)do eq(src.volume,0,'mute applies to every owned voice')end
Sound.setVolumeLevel(3);for _,src in ipairs(made)do eq(src.volume,.8*3/7*(src.name=='exp.wav' and .75 or 1),'cue gain preserves SFX slider, not BGM volume')end
Sound.setVolumeLevel(7)
for _,src in ipairs(made)do eq(src.volume,.8*(src.name=='exp.wav' and .75 or 1),'gain survives mute/slider round trip without compounding')end
-- Gen1 reward tags the actual native message row without reading English text or
-- invoking the EXP helper twice. False announcements never arm a future row.
local amount=0
local mon={level=25,hp=50}
local function award(ctx)
 return ctx.applyShare(mon,2,true)
end
local ctx={battle=b,applyShare=function(m,split,announce)
 amount=amount+20
 events:emit('battle.exp_gained',{battle=b,mon=m,gained=20})
 if announce then b:sayNext('任意の翻訳 — not English')end
 return 20,nil,'preserved'
end}
b.queue={};b.nextInsert=0
local a,n,c=hooks.handlers['battle.exp_award'](award,ctx)
eq(amount,20,'native award applied once');eq(a,20,'return value retained');eq(n,nil,'nil return retained');eq(c,'preserved','return tail retained')
eq(b:updateQueue(),'native-update','native queue result preserved');check(A.status().expPlaying,'Gen1 cue begins when award message appears')
clock=clock+.7;Music.update();check(not A.status().expPlaying,'reading message forever does not loop EXP forever')
local prior=A.status().totals.exp
for _,level in ipairs({25,100})do
 mon.level=level;b.queue={};b.nextInsert=0
 ctx.applyShare=function(m)events:emit('battle.exp_gained',{battle=b,mon=m,gained=level==25 and 0 or 20});b:sayNext('reward')end
 hooks.handlers['battle.exp_award'](award,ctx);b:updateQueue()
end
eq(A.status().totals.exp,prior,'zero EXP and level cap remain silent')
local original=function()error('native intentional error')end
ctx.applyShare=original
check(not pcall(hooks.handlers['battle.exp_award'],award,ctx),'native award errors propagate')
eq(ctx.applyShare,original,'applyShare restored after native error')
b.queue={};b.nextInsert=0;b:sayNext('unrelated');b:updateQueue();eq(A.status().totals.exp,prior,'error leaves no stray EXP scope')
-- Actual stack ownership: Gold has no isBattleState flag; stale battles sharing
-- the game cannot inherit either reward sounds or victory deduplication.
local player={level=50};local partner={level=40}
local gold=setmetatable({game=game,battle={party={player,partner},player=player,outcome='win'},queue={}},{__index=C2})
game.stack.states={gold,{screenId='StatBox'}}
check(type(Sound.play({},'Sfx_DexFanfare5079'))=='table','Gen2 level works under stats overlays')
Sound.stop('Sfx_DexFanfare5079');Music.update()
gold.queue={{kind='experience',index=1,amount=30}};gold:advanceQueue();check(not A.status().expPlaying,'active EXP waits for native bar clock')
gold.expAnim=nil;gold.queue={{kind='experience',index=2,amount=30}};gold:advanceQueue();check(A.status().expPlaying,'bench/doubles partner EXP has bounded feedback')
clock=clock+.7;Music.update();check(not A.status().expPlaying,'bench feedback ends')
partner.level=100;gold.queue={{kind='experience',index=2,amount=30},{kind='level',index=2,level=100}}
gold:advanceQueue();check(A.status().expPlaying,'bench reaching level 100 still has final gain cue')
clock=clock+.7;Music.update();gold.queue={{kind='experience',index=2,amount=30}}
gold:advanceQueue();check(not A.status().expPlaying,'already-capped bench has no false gain loop')
partner.level=40

gold.queue={{kind='experience',index=2,amount=0}};gold:advanceQueue();check(not A.status().expPlaying,'zero bench award silent')
hooks.handlers['music.select'](selected,'GOLD_WIN',{reason='victory'});eq(A.status().totals.victory,before+2,'new encounter has independent victory')
check(Music.paused,'victory active')
game.save.colosseumBattle.battleSoundsEnabled=false;Music.update();check(not Music.paused,'turning off stops owned sound and releases duck')
eq(Sound.play({},'Sfx_DexFanfare5079'),'native:Sfx_DexFanfare5079','OFF restores native fanfares')
game.save.colosseumBattle.battleSoundsEnabled=true
gold.battle.outcome='lose'
eq(hooks.handlers['music.select'](selected,'LOSE',{reason='victory'}),'LOSE','no custom victory on loss')
eq(hooks.handlers['music.select'](selected,'RUN',{reason='battle'}),'RUN','ordinary music selection not intercepted')
game.stack.states={};Music.update();eq(Sound.play({},'Level_Up'),'native:Level_Up','leaving battle restores world learning')
eq(hooks.handlers['music.select'](selected,'MAP',{reason='map'}),'MAP','engine owns map restoration')
eq(reads,startReads,'zero cache reads across all triggers/updates');eq(creates,startCreates,'zero Source allocations across triggers')
-- Missing audio is fail-soft: no suppression and no fake playing ticket.
local brokenV={mod={game=game,hooks={wrap=function()end},events=events},BattleAudioSpec=S,
 GeneratedAssets={read=function()return nil end},engineRequire=function(p)return assert(modules[p])end}
local broken=loadMod('lib/BattleAudio.lua',brokenV)
check(not broken.preload(),'incomplete cache not silently advertised ready')
check(broken.status().errors.level~=nil,'missing cue is diagnosable')
local fallbackSound={play=function(_,name)return 'fallback:'..name end}
local fallbackMusic={update=function()end}
local fallbackHooks={wrap=function()end}
local fallbackGame={save={options={sfxVol=7}},stack={states={b}}}
local fallbackMod={game=fallbackGame,hooks=fallbackHooks}
local fallback=loadMod('lib/BattleAudio.lua',{mod=fallbackMod,BattleAudioSpec=S,
 GeneratedAssets={read=function()return nil end},engineRequire=function(path)
  if path=='src.core.Sound'then return fallbackSound end
  if path=='src.core.Music'then return fallbackMusic end
  return {}
 end})
check(fallback.install(fallbackMod),'missing cue cache does not block installation')
eq(fallbackSound.play({},'Level_Up'),'fallback:Level_Up','unavailable cue keeps native sound, not a fake wait')
eq(fallback._test.victoryWrapper(selected,'NATIVE_WIN',{reason='victory'}),'NATIVE_WIN','missing victory retains native selected song')
print('BattleAudioRuntimeTests: '..checks..' assertions passed')
