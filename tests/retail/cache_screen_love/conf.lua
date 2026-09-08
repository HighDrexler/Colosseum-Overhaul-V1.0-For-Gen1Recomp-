function love.conf(t)
 t.identity='cbe-cache-view-validation';t.version='11.5';t.console=true
 t.window.width=tonumber(os.getenv('CBE_RENDER_WIDTH')) or 1280;t.window.height=tonumber(os.getenv('CBE_RENDER_HEIGHT')) or 720;t.window.resizable=false;t.window.vsync=0
 t.modules.audio=false;t.modules.joystick=false;t.modules.physics=false
end
