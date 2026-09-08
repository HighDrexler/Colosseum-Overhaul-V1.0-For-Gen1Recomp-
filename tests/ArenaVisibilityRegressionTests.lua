local checks=0;local function eq(a,b,l)checks=checks+1;assert(a==b,l..': '..tostring(a)..' ~= '..tostring(b))end
local R=assert(loadfile('lib/Arena.lua'))({})
local gate=R._test.sourceVertexAlphaEnabled
-- Real Orre source flags: opaque, source RGB enabled, vertex alpha can be zero.
for _,flags in ipairs({16402,16434})do
 eq(gate({useVertexColor=true,renderFlags=flags}),false,'opaque source alpha not a visibility mask')
 eq(gate({useVertexColor=true,renderFlags=flags,xlu=false}),false,'fresh opaque agrees')
 eq(gate({useVertexColor=true,renderFlags=flags+1073741824}),true,'packed XLU alpha retained')
 eq(gate({useVertexColor=true,renderFlags=flags+1073741824,xlu=true}),true,'fresh XLU agrees')
end
eq(gate({useVertexColor=false,renderFlags=1073741824}),false,'disabled vertex color leaves alpha unchanged')
for _,shader in ipairs({R._test.pixel,R._test.mobilePixel})do
 eq(shader:find('uniform float sourceVertexAlpha;',1,true)~=nil,true,'independent alpha uniform')
 eq(shader:find('mix(1.0,tint.a,step(0.5,sourceVertexColor))',1,true),nil,'RGB no longer erases opaque source wall')
 eq(shader:find('mix(1.0,tint.a,step(0.5,sourceVertexAlpha))',1,true)~=nil,true,'transparent vertex alpha remains available')
end
local C=assert(loadfile('lib/ArenaAudienceProfile.lua'))()
local I=assert(loadfile('lib/ArenaCacheIdentity.lua'))()
local B=assert(loadfile('extract/ArenaBuilder.lua'))({ArenaAudienceProfile=C,ArenaCacheIdentity=I})
local files={};love={data={pack=function(kind,fmt,...)return string.pack(fmt,...)end}}
local mod={cache={read=function(_,p)return files[p]end,write=function(_,p,s)files[p]=s;return true end,info=function(_,p)local s=files[p];return s and {size=#s,type='file'}end}}
local spec;for _,s in ipairs(B._test.arenas)do if s.id=='water' then spec=s end end
local texture={path='cache/stages/water/source/tex_0d5b60_128x128_f14.rgba',w=128,h=128}
files[texture.path]=string.rep(string.char(255,255,255,255),128*128-1)..string.char(0,0,0,0)
local groups={}
for _,y in ipairs({63,110,145})do groups[#groups+1]={vertices={{0,y,0,0,0,1,1,1,1,0,1,0},{1,y,0,1,0,1,1,1,1,0,1,0},{0,y+1,0,0,1,1,1,1,1,0,1,0}},texture=texture,alpha=1}end
local cache={groups=groups,crowdPolicy='source-hsd-crowd',crowdOriginal=3,bounds={},source='fixture'}
B._test.writeRuntimeSidecar(mod,spec,cache,123,{},function()end,'fixture')
local meta;for p,s in pairs(files)do if p:match('/scene%.lua$')then meta=assert(load(s))()end end
assert(meta,'sidecar emitted')
eq(#meta.crowd,3,'all three exact source banks survive')
eq(meta.crowdOutliers,0,'authored upper banks not outliers');eq(meta.audienceRevision,2,'fixed audience stamp')
eq(B._test.runtimeUsable(mod,meta,spec,123,'fixture'),true,'new crowd sidecar accepted')
meta.audienceRevision=nil;eq(B._test.runtimeUsable(mod,meta,spec,123,'fixture'),false,'old truncated audience cache refreshes')
local other={id='orre_colosseum',cache=spec.cache};eq(B._test.runtimeUsable(mod,meta,other,123,'fixture'),true,'unrelated arena sidecars retain validity')
cache.crowdPolicy='legacy';B._test.writeRuntimeSidecar(mod,spec,cache,123,{},function()end,'fixture')
for p,s in pairs(files)do if p:match('/scene%.lua$')then meta=assert(load(s))()end end
eq(#meta.crowd,1,'legacy outlier filter retained');eq(meta.crowdOutliers,2,'legacy high cards still filtered')
print('ArenaVisibilityRegressionTests: '..checks..' checks passed')
