"""Test-only LuaJIT runner for an installed LÖVE lua51.dll (Windows)."""
import ctypes
import os
from pathlib import Path
import sys

library = Path(sys.argv[1]).resolve()
directory = os.add_dll_directory(str(library.parent))
lua = ctypes.CDLL(str(library))
lua.luaL_newstate.restype = ctypes.c_void_p
lua.luaL_openlibs.argtypes = [ctypes.c_void_p]
lua.luaL_loadstring.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
lua.lua_pcall.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_int, ctypes.c_int]
lua.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.POINTER(ctypes.c_size_t)]
lua.lua_tolstring.restype = ctypes.c_char_p
lua.lua_close.argtypes = [ctypes.c_void_p]
state = lua.luaL_newstate()
lua.luaL_openlibs(state)
def quote(value):
    value = value.replace('\\', '/')
    delimiter = '='
    while ']' + delimiter + ']' in value:
        delimiter += '='
    return '[' + delimiter + '[' + value + ']' + delimiter + ']'
script = 'arg={' + ','.join(quote(s) for s in sys.argv[3:]) + '}; dofile(' + quote(sys.argv[2]) + ')'
status = lua.luaL_loadstring(state, script.encode('utf-8'))
if not status:
    status = lua.lua_pcall(state, 0, -1, 0)
if status:
    print(lua.lua_tolstring(state, -1, None).decode('utf-8', errors='replace'), file=sys.stderr)
lua.lua_close(state)
sys.exit(1 if status else 0)
