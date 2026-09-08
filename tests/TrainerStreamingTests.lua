local savedLove=love
local reads,uploads=0,0
local function mesh()
 return {attachAttribute=function()end,detachAttribute=function()end,release=function()end,setVertices=function()uploads=uploads+1 end}
end
love={graphics={newMesh=mesh},data={newByteData=function(bytes)return {release=function()end} end}}
local clip={count=4,endFrame=3,groups={{path='shared.f32',vertices=3}}}
local track={version=1,fps=1,roles={idle=clip,gesture=clip,throw=clip,sendout=clip,reaction=clip}}
local V={RuntimeMeshCache={readLua=function()return track end},GeneratedAssets={read=function()reads=reads+1;return string.rep('\0',4*3*24)end}}
local M=assert(loadfile('lib/TrainerMorph.lua'))(V)
local groups={{mesh=mesh()}}
assert(M.loadTracks('test',groups)==track and reads==1,'role aliases reread identical source bytes')
assert(M.loadTracks('test',{{mesh=mesh()}})==track and reads==1,'resident track reread from disk')
M.bindPair(groups,{nativeAge=.1});local first=uploads
M.bindPair(groups,{nativeAge=.2});assert(uploads==first,'subframe interpolation uploads unchanged source frames')
M.bindPair(groups,{nativeAge=1.1});assert(uploads-first==1,'adjacent frame reuse should upload only new B frame')
M.releaseTracks(groups);assert(groups[1].nativeBuffers==nil and groups[1].nativeClip==nil,'GPU state retained after release')
love=savedLove
print('PASS: aliased clip reads 5->1; repeated resident reads 1->0; advancing idle uploads 3->1 per group')
