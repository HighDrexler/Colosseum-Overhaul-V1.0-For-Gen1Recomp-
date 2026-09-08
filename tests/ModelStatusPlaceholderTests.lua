-- UI regression: transient model handoff failures must not flash MODEL ERROR.
local f=assert(io.open('UIMain.lua','rb'));local src=f:read('*a');f:close()
local checks=0;local function yes(v,m)checks=checks+1;assert(v,m)end
yes(src:find('function GoldCompat.drawColosseumModelStatus',1,true)~=nil,'status renderer present')
yes(src:find('local label=why and nil or "LOADING MODEL"',1,true)~=nil,'error state intentionally has no visible label')
yes(src:find('"MODEL ERROR"',1,true)==nil,'MODEL ERROR literal removed from UI renderer')
yes(src:find('persistent failures',1,true)~=nil,'diagnostic path remains documented')
print('ModelStatusPlaceholderTests: '..checks..' checks PASS; transient errors render blank while pending loading text remains')
