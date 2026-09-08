local H=assert(loadfile('extract/HSD.lua'))({})
local matrix,multiply=H._test.localMatrix,H._test.multiply
local checks=0
local function check(v,label)checks=checks+1;assert(v,label)end
local function near(a,b,label)check(math.abs(a-b)<1e-6,label)end
-- A forest parent and its child use inverse rotations and reciprocal scales.
-- Their composed orientation must cancel. Plain SRT multiplication instead
-- shears the source leaf cluster because rotation and nonuniform scale differ.
local inherited={30,15,1.5}
local parent=matrix(0,-.404,0,30,15,1.5,0,0,0)
local child=matrix(0,.404,0,1/30,1/15,1/1.5,0,0,0,inherited)
local native=multiply(parent,child)
for row=0,3 do for col=0,3 do near(native[row*4+col+1],row==col and 1 or 0,'native forest transforms did not cancel')end end
local legacy=multiply(parent,matrix(0,.404,0,1/30,1/15,1/1.5,0,0,0))
check(math.abs(legacy[3])>6,'fixture no longer reproduces the giant sheared foliage')
-- Native material selection is retained while enabling the corrected matrix
-- path in the actual builder. No broad geometry predicate may erase the grove.
local seen,writes={},{}
local fixture={groups={},vertexCount=2016,sceneRoots=2,bounds={min={-900,-9,-900},max={900,250,900}}}
for gi=1,8 do local g={vertices={},renderFlags=0x4012,useVertexColor=true,diffuse={.7,.7,.6},alpha=1}
 for vi=1,252 do g.vertices[vi]={vi%3==0 and 900 or -900,100,vi%2==0 and 900 or -900,0,0,.7,.8,.9,1,0,1,0}end
 fixture.groups[gi]=g
end
local V={HSD={extractSceneModel=function(blob,opts)
 check(blob=='scene-fixture','source member was replaced')
 check(opts.nativeScaleCompensation==true,'Relic did not enable the native transform evaluator')
 check(opts.honorRenderPass and opts.skipShadowMaterials,'native pass visibility changed')
 check(opts.preserveVertexColors==true,'source vertex colors were discarded')
 check(opts.groupFilter==nil,'whole-group overhang rejection still deletes source forest')
 seen.options=opts;return fixture
end},FSYS={open=function()return {member=function()return {name='M3_shrine_1F_bf.dat',modelKind=true}end,extract=function()return 'scene-fixture'end}end}}
local B=assert(loadfile('extract/ArenaBuilder.lua'))(V)
local spec;for _,s in ipairs(B._test.arenas)do if s.id=='relic_chamber' then spec=s end end
check(spec~=nil and spec.nativeScaleCompensation==true,'Relic catalog lost source transform policy')
local cave;for _,s in ipairs(B._test.arenas)do if s.id=='relic_cave' then cave=s end end
check(cave and cave.nativeScaleCompensation==true,'Relic Cave branches lost the native scale evaluator')
local mod={cache={write=function(_,path,data)writes[path]=data;return true end}}
local result=B._test.buildSourceArena(mod,{file=function()return {path=spec.sourceFsys}end},function()end,{},spec)
check(result.groups==8 and result.vertices==2016,'builder changed source geometry count')
local parsed=assert(load(writes[spec.cache]))()
check(#parsed.groups[1].vertices[1]==12,'builder lost source color/normal vertex channels')
check(parsed.groups[1].useVertexColor==true,'vertex material flag did not reach canonical cache')
near(parsed.groups[1].vertices[1][7],.8,'source vertex color changed')
print('PresentationFidelitySweepRelicScaleTests: '..checks..' assertions passed')
return true
