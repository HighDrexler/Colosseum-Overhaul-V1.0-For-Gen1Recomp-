love={system={getOS=function() return "Windows" end}}
local Dex={supported=function(d) return tonumber(d) and tonumber(d)>=1 and tonumber(d)<=251 end}
local A=assert(loadfile("lib/PokemonActors.lua"))({
  mod={},Mat4={},GeneratedAssets=nil,RuntimeMeshCache=nil,ColosseumDex=Dex,
})
local game={
  data={pokemon={A={dex=1},B={dex=2},C={dex=3}}},
  save={
    party={{species="A",moves={}}},
    boxes={
      {{species="B"},{species="B"}},
      {{species="C"},{species="A"}},
    },
  },
}
local n=A.queueHardCache(game)
local hs=A.hardCacheStatus()
-- Party A: base + idle + damage + faint = 4. Unique box-only B/C = 2 storage rows.
assert(n==6 and hs.total==6,"hard cache did not include unique boxed species correctly")
assert(hs.storage==0,"storage progress should be zero before pumping")
print("HardCacheStorageQueueTests: OK")
