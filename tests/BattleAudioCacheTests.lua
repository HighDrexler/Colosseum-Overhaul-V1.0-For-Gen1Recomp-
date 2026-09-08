local root=os.getenv('CBE_DOUBLES_MOD_DIR') or '.'
local function loadMod(p,v)return assert(loadfile(root..'/'..p))(v)end
local S=loadMod('lib/BattleAudioSpec.lua');local P=loadMod('extract/PortableMusyX.lua')
local checks=0
local function check(v,msg)checks=checks+1;assert(v,msg)end
local function le(n,count)local out={};for i=1,count do out[i]=string.char(n%256);n=math.floor(n/256)end;return table.concat(out)end
local function be(n,count)return le(n,count):reverse()end
local function wav(rate,frames)
 local data=string.rep('\1\0\2\0',frames)
 return 'RIFF'..le(36+#data,4)..'WAVEfmt '..le(16,4)..le(1,2)..le(2,2)..le(rate,4)..le(rate*4,4)..le(4,2)..le(16,2)..'data'..le(#data,4)..data
end
-- Empty keymap/layer offsets in BOTH actual SFX banks mean absent, not offset 0.
local sm=be(16,4)..be(390,2)..'\0\0'..string.rep('\0',8)..string.rep('\255',4)
local tbl=be(16,4)..be(0,2)..'\0\0'..le(0,2)..le(0,2)..le(4096,2)..le(80,2)..string.rep('\255',4)
local pool=be(16,4)..be(16+#sm,4)..be(0,4)..be(0,4)..sm..tbl
local parsed=P._test.parsePool(pool)
check(parsed.macros[390]~=nil,'present macro retained')
check(parsed.tables[0] and parsed.tables[0].sustain==1,'tables before absent sections retained')
check(next(parsed.keymaps)==nil and next(parsed.layers)==nil,'absent sections remain empty')
local malformed=be(0,4)..be(0,4)..be(0,4)..be(16,4)..be(12,4)..be(1,2)..'\0\0'..be(4294967295,4)
check(not pcall(P._test.parsePool,malformed),'malformed huge layer count fails before allocation')
check(not pcall(P._test.parsePool,be(99999,4)..string.rep('\0',12)),'bad offset rejected')
for _,cue in ipairs(S.cues)do
 local b=wav(cue.rate,100)
 check(S.validWav(b,cue.rate),cue.id..' valid WAV')
 check(S.ready(cue,b,S.marker(cue,b)),'verified marker')
 check(not S.ready(cue,b:sub(1,-2)..'x',S.marker(cue,b)),'same-sized corruption rejected')
 check(not S.validWav(b:sub(1,-2),cue.rate),'truncation rejected')
 check(not S.validWav(b,cue.rate+1),'wrong rate rejected')
end
local macro=string.rep('\0',24)..string.char(0,0,68,25,0,0,1,0,0,0,9,16,0,0,0,0,
 1,0,0,7,0,48,0,0,0,0,1,5,255,255,0,0)..string.rep('\0',32)
local rel=string.rep('\0',0x141654+1232*12)..string.char(192,6,1,10,3,207)..string.rep('\0',0x14BF38-(0x141654+1232*12+6))..be(1236,4)
local renderCalls=0
local renderer={hasSfx=function(_,id)return id==975 end}
function renderer.prepareSfx()return{project={groupId=6},pool={macros={[390]=macro}}}end
function renderer.prepare()return{}end
function renderer.renderSfx(_,id,rate)
 check(id==975,'source SFX id, NOT game sound ID, passed to renderer');renderCalls=renderCalls+1
 return wav(rate,3072),{peak=.7,voices=1,clipped=0,entry={obj=390}}
end
function renderer.renderSong(_,seq,setup,loop,rate)
 check((seq=='level_up_song' and setup==1) or (seq=='me_win_song' and setup==10),'source song matches setup')
 check(loop==nil,'fanfares never rendered as looping songs');renderCalls=renderCalls+1
 return wav(rate,100),nil,{peak=.7,voices=12,clipped=0}
end
local names={'snd_se_proj','snd_se_pool','snd_se_sdir','snd_music_proj','snd_music_pool','snd_music_sdir','common_rel','level_up_song','me_win_song'}
local archive={list=function()local out={};for _,n in ipairs(names)do out[#out+1]={name=n}end;return out end,
 extract=function(_,entry)return entry.name=='common_rel' and rel or entry.name end}
local disc={file=function(_,name)return name end,readFile=function(_,file)return file end}
local FSYS={open=function()return archive end}
local B=loadMod('extract/BattleAudioBuilder.lua',{FSYS=FSYS,PortableMusyX=renderer,BattleAudioSpec=S})
local files={['.cbe-source-audio-v9.complete']='EXISTING MUSIC',['cache/pokemon/058']='SHINY/MODELS',['cache/arena/water']='CROWD'}
local writes,opens=0,0
local cache={read=function(_,path)return files[path]end,write=function(_,path,b)writes=writes+1;files[path]=b;return true end}
local function openDisc()opens=opens+1;return disc end
local result=B.run({cache=cache},openDisc)
check(result.ready and result.built==3 and result.complete==3,'first pass builds all three')
check(opens==1,'one source open')
check(#files[S.cues[1].path]==6188,'48ms source cycle, no renderer release-tail gap')
check(writes==6,'one WAV + verified marker per cue')
local hit=B.run({cache=cache},function()error('must not open source')end)
check(hit.ready and hit.reused==3 and hit.built==0,'full hit is source-free')
check(writes==6 and renderCalls==3,'hit neither writes nor renders')
files[S.cues[1].path]=files[S.cues[1].path]:sub(1,-2)..'X'
local repaired=B.run({cache=cache},openDisc)
check(repaired.ready and repaired.built==1 and repaired.reused==2,'only corrupt cue repaired')
check(files['.cbe-source-audio-v9.complete']=='EXISTING MUSIC' and files['cache/pokemon/058']=='SHINY/MODELS' and files['cache/arena/water']=='CROWD','no prior cache invalidation')
files[S.markerPath(S.cues[2])]=nil
local oldWrite=cache.write
cache.write=function(self,path,b)if path==S.cues[2].path then return false,'disk full'end;return oldWrite(self,path,b)end
local failed=B.run({cache=cache},openDisc)
check(not failed.ready and failed.complete==2 and failed.errors.level,'disk failure is per-cue and visible')
check(files[S.markerPath(S.cues[2])]==nil,'incomplete file never marked complete')
cache.write=oldWrite
local resumed=B.run({cache=cache},openDisc)
check(resumed.ready and resumed.built==1 and resumed.reused==2,'retry retains successful cues')
check(not pcall(B.trimExp,wav(32000,3072),{entry={obj=391}}),'wrong sample macro rejected')
check(not pcall(B.validateExpSource,rel,{project={groupId=5},pool={macros={[390]=macro}}}),'wrong bank rejected')
print('BattleAudioCacheTests: '..checks..' assertions passed')
