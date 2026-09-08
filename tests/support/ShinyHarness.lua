-- In-memory source/cache and graphics doubles; no retail assets or real GPU.
local H={}
function H.new(options)
 options=options or {}
 local h={files=options.files or {},reads={},writes={},extracts={},metadataReads={},meshes=0,images=0,draws=0,clock=0,source=true}
 local function copy(t) if type(t)~='table' then return t end;local r={};for k,v in pairs(t)do r[k]=copy(v)end;return r end
 h.copy=copy
 local function object()return {release=function(self)self.released=true end,setFilter=function()end,setTexture=function(self,t)self.texture=t end,
  setWrap=function()end,setVertices=function(self,d)self.bytes=d.bytes end}end
 h.shader=object();h.shader.uniforms={};function h.shader:send(k,...)self.uniforms[k]=copy({...})end
 local noop=function()end
 love={timer={getTime=function()return h.clock end},system={getOS=function()return options.os or 'Windows'end},
  graphics={newShader=function(v,p)h.vertexShader=v;h.pixelShader=p;return h.shader end,
   newMesh=function(format,rows)h.meshes=h.meshes+1;local m=object();m.rows=copy(rows);return m end,
   newImage=function()h.images=h.images+1;return object()end,
   draw=function(m)assert(not m.released,'released mesh drawn');h.draws=h.draws+1 end,
   setShader=noop,setColor=noop,push=noop,pop=noop,setDepthMode=noop,setBlendMode=noop,setMeshCullMode=noop},
  image={newImageData=function()return object()end},
  data={pack=function(kind,format,...)assert(kind=='string');return string.pack(format,...)end,
   newByteData=function(bytes)local d=object();d.bytes=bytes;return d end}}
 h.Assets={read=function(path)h.reads[path]=(h.reads[path] or 0)+1;return h.files[path]end,
  info=function(path)if h.files[path] then return {type='file',size=#h.files[path]}end end,
  write=function(path,value)if h.failWrite and h.failWrite==path then return false,'simulated write failure' end;h.files[path]=value;h.writes[path]=(h.writes[path]or 0)+1;return true end,
  exists=function(path)return h.files[path]~=nil end}
 h.mod={id='fixture',cache={read=function(_,p)return h.Assets.read(p)end,info=function(_,p)return h.Assets.info(p)end,
  write=function(_,p,v)return h.Assets.write(p,v)end}}
 h.Dex=assert(loadfile('lib/ColosseumDex.lua'))();h.Shiny=assert(loadfile('lib/ShinySupport.lua'))()
 h.R=assert(loadfile('lib/RuntimeMeshCache.lua'))({GeneratedAssets=h.Assets})
 h.filter={version=1,route={2,0,1},gain={.5,1.25,1.5}}
 h.extractor={cachePath=function(key)return h.Dex.cacheRoot(key)..'/model_cache.lua'end,
  revPath=function(key)return h.Dex.cacheRoot(key)..'/rev.txt'end,stamp=function()return 'fixture-geometry-37'end}
 h.template={stem='fixture-body',bounds={min={-1,0,-1},max={1,16,1}},morphFrames=0,groups={},actions={}}
 local rows={};for i=1,3 do local row={};for j=1,44 do row[j]=0 end;row[1]=i-2;row[2]=(i-1)*8;row[7]=1
  for f=0,11 do row[9+f*3]=row[1];row[10+f*3]=row[2];row[11+f*3]=0 end;rows[i]=row end
 h.template.groups={{vertices=rows,diffuse={.8,.3,.2},alpha=.75}}
 function h.putModel(key)
  h.R.writeLua(h.extractor.cachePath(key),h.copy(h.template));h.files[h.extractor.revPath(key)]='fixture-geometry-37'
 end
 function h.putMetadata(key,filter)
  local path=h.Dex.cacheRoot(key)..'/metadata_v1.lua'
  h.R.writeLua(path,{revision=filter and 4 or 3,shinyFilter=filter and h.copy(filter) or nil,slots={},bodyMap={}})
 end
 function h.extractor.extractSpecies(mod,disc,dex,opts)
  h.extracts[#h.extracts+1]={dex=dex,variant=opts.variant or h.Dex.variant(dex)}
  if h.extractFail then return nil,h.extractFail end
  if opts.progress then h.clock=h.clock+.01;opts.progress()end
  local key=h.Dex.modelKey(dex,opts.variant);h.putModel(key);h.putMetadata(key,h.filter)
  return {path=h.extractor.cachePath(key)}
 end
 local metadata={inspectSpecies=function(disc,dex,variant,form,opts)
  h.metadataReads[#h.metadataReads+1]={dex=dex,variant=variant}
  if h.metadataFail then return nil,h.metadataFail end
  if opts and opts.progress then h.clock=h.clock+.01;opts.progress()end
  return {shinyFilter=h.copy(h.filter),slots={},bodyMap={}}
 end}
 function h.newActors()
  local A=assert(loadfile('lib/PokemonActors.lua'))({mod=h.mod,Mat4=assert(loadfile('lib/Mat4.lua'))(),ColosseumDex=h.Dex,
   ShinySupport=h.Shiny,GeneratedAssets=h.Assets,RuntimeMeshCache=options.disk and h.R or nil})
  A.install(h.extractor,function()if h.source then return {}end end,nil,metadata)
  return A
 end
 h.A=h.newActors()
 h.game={data={pokemon={TEST={dex=25},RARE={dex=6},SECOND={dex=1}}},save={party={},boxes={}}}
 function h.opts(mon,information)
  return {battler={mon=mon},side='player',context={game=h.game,arena={figureScale=.38},services={informationSurface=information==true}}}
 end
 return h
end
return H
