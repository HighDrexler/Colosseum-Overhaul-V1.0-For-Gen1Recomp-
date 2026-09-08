-- Regression for real source image identities shared by different GX samplers.
local n=0;local function eq(a,b,label)n=n+1;assert(a==b,label..': '..tostring(a)..' ~= '..tostring(b))end
local made,reads=0,0
local oldLove=love
love={image={newImageData=function()return {}end},graphics={newImage=function()
 made=made+1;local image={}
 function image:setFilter()end
 function image:setWrap(s,t)self.wrapS=s;self.wrapT=t end
 return image
end}}
local R=assert(loadfile('lib/Arena.lua'))({GeneratedAssets={read=function()reads=reads+1;return string.rep('\255',16)end}})
local textures={};local path='cache/stages/deep/source/tex_0958c0_2x2_f14.rgba'
local function spec(s,t)return {path=path,w=2,h=2,wrapS=s,wrapT=t}end
local clamp=assert(R._test.texture(spec(0,0),textures))
local vRepeat=assert(R._test.texture(spec(0,1),textures))
local repeatBoth=assert(R._test.texture(spec(1,1),textures))
eq(clamp.image==vRepeat.image,false,'same pixels retain independent GX sampler state')
eq(vRepeat.image==repeatBoth.image,false,'each distinct source wrap pair isolated')
eq(clamp.image.wrapS,'clamp','clamp S retained');eq(clamp.image.wrapT,'clamp','clamp T retained')
eq(vRepeat.image.wrapS,'clamp','mixed wrap S retained');eq(vRepeat.image.wrapT,'repeat','mixed wrap T retained')
eq(repeatBoth.image.wrapS,'repeat','repeat S retained');eq(repeatBoth.image.wrapT,'repeat','repeat T retained')
eq(R._test.texture(spec(0,0),textures),clamp,'same material reuses existing image')
eq(R._test.texture(spec(0,1),textures),vRepeat,'mixed material reuses existing image')
local blendSpec=spec(0,0);blendSpec.colorMap=3;blendSpec.blending=.35
eq(R._test.texture(blendSpec,textures),clamp,'texture color combiner is per group, not image sampler state')
eq(made,3,'no repeated image creation for identical source state');eq(reads,3,'no repeated file read for identical source state')
local mirrored=assert(R._test.texture(spec(2,2),textures))
eq(mirrored.image.wrapS,'mirroredrepeat','GX mirror state retained')
eq(mirrored.image.wrapT,'mirroredrepeat','GX mirror T retained')
love=oldLove
for _,s in ipairs({R._test.pixel,R._test.mobilePixel})do
 eq(s:find('sourceVertexColor > 0.5 ? sourceTint.rgb : materialDiffuse',1,true)~=nil,true,'unlit vertex OR constant source selection')
 eq(s:find('sourceDiffuseLighting < 0.5 && !(sceneProfile > 0.5 && sceneProfile < 1.5)',1,true)~=nil,true,'source unlit returns before authored grades')
 eq(s:find('mix(sourceBase,texel.rgb,clamp(sourceTextureBlending,0.0,1.0))',1,true)~=nil,true,'source BLEND color operation preserved')
end
print('ArenaMaterialFidelityTests: '..n..' assertions passed')
