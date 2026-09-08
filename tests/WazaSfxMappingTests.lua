local function put32(bytes,offset,value)
  local packed=string.char(math.floor(value/16777216)%256,math.floor(value/65536)%256,math.floor(value/256)%256,value%256)
  return bytes:sub(1,offset)..packed..bytes:sub(offset+5)
end
local definitions=put32(string.rep("\0",0x14BF3C),0x14BF38,1236)
definitions=put32(definitions,0x141654+133*12,0x8005010A)
definitions=put32(definitions,0x141654+133*12+4,248*65536)
local files={
  ["cache/waza/sfx/0133.wav"]="RIFF0000WAVE"..string.rep("old",20),
  ["cache/waza/sfx/0002.wav"]="RIFF0000WAVE"..string.rep("old",20),
}
local fresh="RIFF0000WAVE"..string.rep("new",20)
local cache={}
function cache:read(path)return files[path]end
function cache:write(path,bytes)files[path]=bytes;return true end
function cache:delete(path)files[path]=nil;return true end
function cache:info(path)return files[path] and {size=#files[path]}end
local members={"common_rel","snd_se_battle_proj","snd_se_battle_pool","snd_se_battle_sdir"}
local archive={}
function archive:list()local entries={};for _,name in ipairs(members)do entries[#entries+1]={name=name}end;return entries end
function archive:extract(entry)return entry.name=="common_rel" and definitions or "source"end
local renders=0
local builder=assert(loadfile("extract/WazaSfxBuilder.lua"))({
  FSYS={open=function()return archive end},
  PortableMusyX={
    prepareSfx=function()return {project={groupId=5}}end,
    hasSfx=function(_,id)return id==248 end,
    renderSfx=function(_,id)
      assert(id==248,"builder rendered GameSound as a direct SFX ID")
      renders=renders+1
      return fresh,{peak=.5,frames=20,voices=1,clipped=0,entry={sourceId=id}}
    end,
  },
})
local disc={file=function(_,name)return name end,readFile=function()return "source"end}
local result=builder.run({cache=cache},disc,{133,2})
assert(result.complete==1 and result.missing==1 and renders==1)
assert(files["cache/waza/sfx/0133.wav"]==fresh,"old misidentified WAV survived rebuild")
assert(files["cache/waza/sfx/0002.wav"]==nil,"unmapped old WAV survived rebuild")
result=builder.run({cache=cache},disc,{133,2})
assert(result.complete==1 and renders==1,"verified cache unnecessarily rendered again")
local assets={info=function(path)return cache:info(path)end,read=function(path)return files[path]end}
local index={version=2,readyIds={133}}
assets.readLua=function()return index end
local audio=assert(loadfile("lib/WazaAudioRuntime.lua"))({GeneratedAssets=assets})
assert(not audio.has(133),"runtime accepted old ordinal-ID audio cache")
index={version=3,renderer="lua-musyx-sfx-v3-gamesound-table",readyIds={133}}
assert(audio.has(133) and not audio.has(2),"runtime ignored verified sound membership")
return true
