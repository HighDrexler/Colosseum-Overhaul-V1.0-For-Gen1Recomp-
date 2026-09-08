local savedLove=love
local reads,plays,resumes=0,0,0
local native={duckForFanfare=function()end,update=function()resumes=resumes+1 end,
 current=function()return 'COLOSSEUM_ENV_LINK1' end,play=function()error('boss handoff skipped the selected theme intro')end}
love={filesystem={newFileData=function(b)return b end},audio={newSource=function()
 return {getDuration=function()return 12 end,setLooping=function()end,setPitch=function(_,p)assert(p==1)end,setVolume=function()end,
 play=function()plays=plays+1 end,stop=function()end,release=function()end}
end}}
local V={GeneratedAssets={read=function(path)reads=reads+1;assert(path=='assets/audio/intro/fanfare00.wav','wrong boss cue');return 'RIFF'..string.rep('\0',4)..'WAVE'..string.rep('\0',40)end},
 engineRequire=function(n)if n=='src.core.Music' then return native end;return {} end,StandaloneHost={session={started=true}}}
local B=assert(loadfile('lib/BossIntro.lua'))(V)
local function battle(enabled)return {trainer={classId='BROCK'},game={save={colosseumBattle={bossIntroEnabled=enabled}}}} end
local off=battle(false);V.StandaloneHost.session.battle=off;assert(not B.begin(off) and reads==0)
local on=battle(true);V.StandaloneHost.session.battle=on
on.game.data={audio={songs={COLOSSEUM_ENV_LINK1={loopFile='loop'}}}}
local s=assert(B.begin(on));assert(plays==1)
B.finish('complete');assert(resumes==1 and not B.active(on));B.finish('complete');assert(resumes==1)
local skip=battle(true);V.StandaloneHost.session.battle=skip;assert(B.begin(skip));B.finish('skipped');assert(resumes==2)
love=savedLove
print('BossIntroCueTests: OK')
