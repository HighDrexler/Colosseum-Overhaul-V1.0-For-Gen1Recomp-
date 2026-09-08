-- Exact source format recovery, not a generic black-key transparency filter.
local P=assert(loadfile('lib/CurrentSpriteModels.lua'))({})
local n=0;local function eq(a,b,k)n=n+1;assert(a==b,k)end
local f=P._test.particleIntensityAlpha
for _,fmt in ipairs({0,1,'0','1'})do eq(f{fmt=fmt},1,'GX intensity formats replicate R into alpha')end
for _,fmt in ipairs({2,3,4,5,6,8,9,10,14,99,'RGBA8','I4'})do eq(f{fmt=fmt},0,'other or untyped texture retains its own alpha')end
eq(f(nil),0,'missing format cannot trigger a guessed alpha rewrite')
eq(f{gray=true},0,'legacy gray alone is not format proof')
eq(f{fmt=6,gray=true},0,'exact RGBA8 format wins over generic gray flag')
local shader=P._test.particleShaderSource
eq(shader:find('if (cbeIntensityAlpha > 0.5) t.a=t.r;',1,true)~=nil,true,'shader restores intensity alpha')
eq(shader:find('t.a=t.r;',1,true)<shader:find('if (t.a < cbeAlphaCutoff)',1,true),true,'source alpha applied before alpha testing')
eq(shader:find('float a=t.a*mix(cbeEnv.a,cbePrim.a,k);',1,true)~=nil,true,'source Prim/Env alpha retained')
print('ParticleIntensityAlphaTests: '..n..' assertions passed')
