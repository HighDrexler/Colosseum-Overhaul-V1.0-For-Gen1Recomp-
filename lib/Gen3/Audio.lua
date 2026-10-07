
local V=...
local req=V.engineRequire or require
local M={}
local FRLG_BATTLE={[296]=true,[297]=true,[298]=true,[299]=true,[339]=true,[340]=true,[341]=true}
local BATTLE_ROLES={'battleWild','battleTrainer','battleGymLeader','battleChampion','battleEliteFour',
'battleRival','battleAquaMagma','battleFrontierBrain'}
local TITLE_ASSET='assets/audio/colosseum_title.ogg'
local titleData
local function titleSource()
if not (love and love.audio and love.audio.newSource and love.filesystem
and love.filesystem.newFileData and V.mod and V.mod.read) then return nil end
if not titleData then
local bytes=V.mod:read(TITLE_ASSET)
if type(bytes)~='string' or #bytes<4 or bytes:sub(1,4)~='OggS' then
return nil
end
local ok,data=pcall(love.filesystem.newFileData,bytes,'colosseum_title.ogg')
if not ok then return nil end
titleData=data
end
local ok,source=pcall(love.audio.newSource,titleData,'stream')
return ok and source or nil
end
local function layout()
local GameVersion=req('src.core.GameVersion')
if type(GameVersion.layout)=='function' then return GameVersion.layout(GameVersion.get()) end
local version=GameVersion.get()
return (version=='emerald' or version=='ruby' or version=='sapphire') and 'rse' or 'frlg'
end
local function isBattleSong(A,id)
local n=tonumber(id);if not n then return false end
if layout()=='frlg' and FRLG_BATTLE[n] then return true end
for _,role in ipairs(BATTLE_ROLES) do if tonumber(A.role(role))==n then return true end end
return false
end
function M.install()
if M.installed then return end
local A=req('src.core.game3.audio')
local play,update,pump,pause,stop=A.playSong,A.update,A.pumpBgm,A.pauseBgm,A.stopAll
local function clear()
local row=M.active;if not row then return end
for _,source in ipairs({row.intro,row.loop}) do
pcall(source.stop,source);pcall(source.release,source)
end
A._bgmSource=row.nativeSource;M.active=nil
end
A.playSong=function(id,opts)
opts=opts or {};local numeric=tonumber(id)
local info=A.songInfo(id)
if opts.fanfare or (info and info.kind=='fanfare') then return play(id,opts) end


if M.menuOwned and id~='CBE_MT_LOBBY' and not isBattleSong(A,id) then return true end
if M.active and M.active.id==id and not opts.restart then return true end
local title=layout()=='rse' and numeric and numeric==tonumber(A.role('title'))
local environment=id=='CBE_MT_LOBBY' and 'mt_battle_lobby'
or (numeric==A.role('pokeCenter') and V.Music.pokemonCenterReplacementEnabled() and 'pokemon_center' or nil)
if not environment and layout()=='frlg'
and numeric==303 and V.Music.pokemonCenterReplacementEnabled() then environment='pokemon_center' end
local track
if isBattleSong(A,id) or environment then track=V.Music.gen3Track(V.Gen3Runtime.game or V.mod.game,environment) end
clear()
if title then
local source=titleSource()
if source then
play(0)
source:setLooping(true)
M.active={id=id,intro=source,single=true,nativeSource=A._bgmSource}
A._bgmSource=source
A._currentSong={id=id,loop=true,startedAt=os.clock()}
A._fadeOut=nil;A._fadeIn=nil;A._fanfareActive=false;A._fanfareRestore=nil
A._bgmPaused=false
A.resumeBgm();return true
end
end
if not (track and love.audio and love.audio.newSource) then
if id=='CBE_MT_LOBBY' then return A.restoreMapSong() end
return play(id,opts)
end
local ok,intro=pcall(love.audio.newSource,track.intro,'stream')
if not ok then M.error=tostring(intro);return play(id,opts) end
local ready,loop=pcall(love.audio.newSource,track.loop,'stream')
if not ready then intro:release();M.error=tostring(loop);return play(id,opts) end
play(0)
M.active={id=id,intro=intro,loop=loop,nativeSource=A._bgmSource}
loop:setLooping(true);A._bgmSource=intro
A._currentSong={id=id,loop=true,startedAt=os.clock()}
A._fadeOut=nil;A._fadeIn=nil;A._fanfareActive=false;A._fanfareRestore=nil
A._bgmPaused=false
A.resumeBgm();return true
end
A.pumpBgm=function(...) if not M.active then return pump(...) end end
A.pauseBgm=function(...)
if not M.active then return pause(...) end
A._bgmPaused=true;if A._bgmSource then A._bgmSource:pause() end
end
A.update=function(dt,...)
if M.menuOwned and V.Gen3UI then
local Stack=req('src.ui.game3.stack');local owned=Stack.has('cbe-gen3')
local hub=V.Gen3MtBattleHub and V.Gen3MtBattleHub.owner
for _,state in ipairs(hub and hub.stack.states or {}) do
if Stack.has(state.__gen3HubId) then owned=true;break end
end
if not owned then V.Gen3UI.close() end
end
local result=update(dt,...);local row=M.active
if row then
if not A._currentSong or A._currentSong.id~=row.id then clear()
elseif not row.single and not A._bgmPaused and not A._suspended and A._bgmSource==row.intro and not row.intro:isPlaying() then
row.loop:setVolume(row.intro:getVolume());A._bgmSource=row.loop;row.loop:play()
end
end
return result
end
A.stopAll=function(...) clear();return stop(...) end
M.installed=true
end
function M.lobby()
M.menuOwned=true
return req('src.core.game3.audio').playSong('CBE_MT_LOBBY')
end
function M.leaveLobby()
M.menuOwned=false
if M.active and M.active.id=='CBE_MT_LOBBY' then return req('src.core.game3.audio').restoreMapSong() end
end
return M
