-- Source spectator geometry contracts. The six venue atlas bottoms are
-- V=.5/.49609375 on the retail GC6E01 disc, rather than a full-card V=1.
local n=0
local function eq(a,b,label)n=n+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local function near(a,b,label)n=n+1;assert(math.abs(a-b)<1e-6,label)end
local P=assert(loadfile('lib/ArenaAudienceProfile.lua'))()
local R=assert(loadfile('lib/Arena.lua'))({ArenaAudienceProfile=P})
local B=assert(loadfile('extract/ArenaBuilder.lua'))({ArenaAudienceProfile=P})
local fixtures={
 {'water','water/source',0x0d5b60,.5},
 {'orre_colosseum','orre/source',0x10f240,.5},
 {'pyrite_colosseum','pyrite/source',0x103580,.49609375},
 {'deep_colosseum','deep/source',0x09d8c0,.49609375},
 {'realgam_colosseum','realgam/source',0x0bed60,.49609375},
 {'mt_battle_summit','d2_crater/textures',0x106ee0,.49609375},
}
for _,f in ipairs(fixtures)do
 local texture={path=('cache/stages/%s/tex_%06x_128x128_f14.rgba'):format(f[2],f[3])}
 eq(B._test.runtimeMaterialMode({texture=texture},true,f[1]),4,'source audience pass '..f[1])
 local rows={{10,63,12,0,f[4],.8,.6,.4,1,0,0,1},{14,63,12,.5,f[4],.8,.6,.4,1,0,0,1},{10,71,12,0,0,.8,.6,.4,1,0,0,1}}
 local packed=B._test.runtimeWithNormals(rows,4,2000)
 local direct=R._test.withNormals(rows,4)
 for i=1,3 do for j=1,12 do near(packed[i][j],direct[i][j],'packed/source parity '..f[1])end
  for j=1,9 do near(packed[i][j],rows[i][j],'authored position, UV and RGBA retained '..f[1])end
 end
end
-- Test the actual shared GPU program, including the absence of atlas-UV-based
-- deformation in the audience branch. GPU coverage/color readback is exercised
-- separately with the real LÖVE renderer in the source-validation harness.
eq(R._test.vertex,R._test.mobileVertex,'same geometry on GLES and desktop')
local audienceVertex=assert(R._test.vertex:match('else if %(materialMode > 3%.5 && materialMode < 4%.5%) {(.-)} else if'))
eq(audienceVertex:find('localPos.',1,true),nil,'no source audience displacement')
for _,s in ipairs({R._test.pixel,R._test.mobilePixel})do
 eq(s:find('uniform float materialMode;',1,true)~=nil,true,'material mode available')
 eq(s:find('< 0.34) discard;',1,true)~=nil,true,'matching hard alpha coverage')
 eq(s:find('crowdLife',1,true),nil,'no synthetic audience color pulses')
 eq(s:find('footShade',1,true),nil,'no atlas-coordinate foot recoloring')
end
print('ArenaSpectatorFidelityTests: '..n..' assertions passed')
