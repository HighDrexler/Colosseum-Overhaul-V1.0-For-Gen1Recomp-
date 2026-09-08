local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local main=read("main.lua")
local bp=read("extract/BuildPipeline.lua")
local probe=read("extract/AudioProbe.lua")
local cache=read("lib/CacheManager.lua")
local music=read("lib/Music.lua")
local sfx=read("extract/WazaSfxBuilder.lua")

assert(main:find("extractionStatus%.visualReady~=true or extractionStatus%.audioReady~=true"),
  "startup no longer hard-gates CBE runtime on source audio readiness")
assert(bp:find("AudioProbe%.runPortableFull",1,false),"canonical portable soundtrack renderer is not invoked")
assert(not bp:find("pcall%(AudioProbe%.run,mod,disc",1,false),"Windows Amuse branch still owns production soundtrack output")
assert(bp:find("audio_required_failed",1,true) and bp:find("runtimeReady=false",1,true),
  "failed audio can still be promoted to runtime-ready")
assert(not bp:find("audio_exhausted=1",1,true),"persistent audio-exhausted downgrade remains reachable")
assert(probe:find("cbe%-audio%-portable=9") and probe:find("lua%-musyx%-canonical%-v9%-cross%-platform%-48k"),
  "canonical v9 cross-platform audio marker missing")
assert(probe:find("PORTABLE_LEDGER_PATH",1,true) and probe:find("verifyMissingSize",1,true) and probe:find("portableAssetsReady(mod,true)",1,true),
  "canonical audio cache does not reject interrupted/truncated WAV commits through the v9 ledger")
assert(bp:find("build/audio_portable_v9_assets.lua",1,true) and cache:find("build/audio_portable_v9_assets.lua",1,true),
  "v9 audio ledger is not covered by migration/reset cleanup")
assert(cache:find("audioLedgerReady",1,true),
  "cache inspector can report canonical audio ready without validating the v9 asset ledger")
local portablePayloadStart=assert(probe:find("local function portablePayload",1,true))
local portablePayloadEnd=assert(probe:find("function A.runPortableFull",portablePayloadStart,true))
local portablePayloadSource=probe:sub(portablePayloadStart,portablePayloadEnd-1)
assert(not portablePayloadSource:find("loopFrame=theme.loopFrame",1,true),
  "portable production soundtrack still trusts hard-coded PCM loop frames")
local portable=read("extract/PortableMusyX.lua")
assert(portable:find("sourceLoopStartTick",1,true) and portable:find("P.renderSong",1,true)
  and portable:find(",true,rate",1,true),
  "portable renderer is not deriving the loop split from the SNG source header")
assert(cache:find("%.cbe%-audio%-portable%-v9%.complete") and cache:find("audioExhausted=false",1,true),
  "cache inspector does not enforce canonical v9 audio readiness")
assert(not music:find("audioExtractionExhausted",1,true),"runtime music still accepts legacy exhausted-audio state")
assert(music:find("ORIGINAL / AUDIO REQUIRED",1,true),"runtime UI does not expose missing source audio as required")
assert(sfx:find("missing~=0 or ready~=requested",1,true) and sfx:find("index.missing==0 and index.ready==index.requested",1,true),
  "MoveFX GameSound completion marker can still be written for a partial render")

-- Functional cache-integrity check: a valid v9 marker plus all filenames is not
-- enough. Every committed WAV must still match the exact size ledger.
local AudioProbe=assert(loadfile("extract/AudioProbe.lua"))({FSYS={},PortableMusyX={}})
local wav="RIFF"..string.rep("\0",4).."WAVE"..string.rep("\0",32)
local store={}
store[".cbe-audio-portable-v1.complete"]=AudioProbe.portableMarker
store[".cbe-audio-portable-v9.complete"]=AudioProbe.portableFullMarker
local ledger={"return {version=9,assets={\n"}
for _,path in ipairs(AudioProbe.portableAssets) do
  store[path]=wav
  ledger[#ledger+1]=string.format("  [%q]={size=%d},\n",path,#wav)
end
ledger[#ledger+1]="}}\n"
store[AudioProbe.portableLedgerPath]=table.concat(ledger)
local fake={cache={}}
function fake.cache:read(path)return store[path]end
function fake.cache:info(path)local v=store[path];return v and {type="file",size=#v} or nil end
function fake.cache:write(path,data)store[path]=data;return true end
function fake.cache:delete(path)store[path]=nil;return true end
assert(AudioProbe.portableFullReady(fake)==true,"valid v9 soundtrack ledger was rejected")

-- Gen1Recomp portable mode may expose file info without a size field. A final
-- v9 marker plus the read-back-created ledger must remain bootable there.
function fake.cache:info(path)local v=store[path];return v and {type="file"} or nil end
assert(AudioProbe.portableFullReady(fake)==true,"metadata-less portable cache backend rejected a committed v9 ledger")
function fake.cache:info(path)local v=store[path];return v and {type="file",size=#v} or nil end
local damaged=AudioProbe.portableAssets[1]
local originalInfo=fake.cache.info
function fake.cache:info(path)
  local info=originalInfo(self,path)
  if info and path==damaged then info.size=info.size-1 end
  return info
end
assert(AudioProbe.portableFullReady(fake)==false,"truncated v9 soundtrack asset survived ledger validation")

return true
