#!/usr/bin/env python3
"""Run packaged top-level regression suites with texlua (Lua 5.3) or LuaJIT.

These isolated fixtures are not a live LÖVE/game test. No network or ROM is used.
Requires Python 3.9+ and a texlua executable on PATH. The test-only Lua wrapper
adapts Lua 5.1-style APIs used by fixtures. It is not part of the runtime mod.
"""
from __future__ import annotations

import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import time


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=Path(__file__).resolve().parent.parent)
    parser.add_argument('--output', type=Path, help='Optional JSON result log; no default overwrite.')
    parser.add_argument('--timeout', type=float, default=30.0, help='Per-suite timeout in seconds.')
    parser.add_argument('--engine-root', type=Path, help='Optional Gen1Recomp checkout for native engine suites.')
    parser.add_argument('--texlua', default='texlua', help='texlua executable or absolute path.')
    parser.add_argument('--luajit', help='Optional LuaJIT executable; uses the real Lua 5.1/FFI test wrapper.')
    parser.add_argument('--lua-dll', type=Path, help='Windows: installed LÖVE lua51.dll; runs its real LuaJIT through ctypes.')
    args = parser.parse_args()
    root = args.root.resolve()
    if args.lua_dll and (os.name != 'nt' or not args.lua_dll.is_file() or args.luajit):
        parser.error('--lua-dll requires an existing Windows DLL and cannot be combined with --luajit.')
    exe = shutil.which(args.luajit or args.texlua) if not args.lua_dll else sys.executable
    if exe is None:
        parser.error('The requested Lua executable was not found; pass --texlua or --luajit.')
    if args.timeout <= 0:
        parser.error('--timeout must be positive')
    wrapper = root / ('tests/luajit_wrapper.lua' if args.luajit or args.lua_dll else 'tests/texlua_wrapper.lua')
    command = [exe, str(root / 'tests/lua_dll_runner.py'), str(args.lua_dll.resolve())] if args.lua_dll else [exe]
    suites = sorted((root / 'tests').glob('*Tests.lua'))
    if not wrapper.is_file() or not suites:
        parser.error('The selected root does not contain the complete tests directory.')
    env = dict(os.environ, CBE_DOUBLES_MOD_DIR=str(root), CBE_DOUBLES_UI_DIR=str(root), UI_COMPAT_DIR=str(root))
    engine = args.engine_root.resolve() if args.engine_root else None
    if engine and not ((engine / 'tests/modkit.lua').is_file() or (engine / 'tests/modkit/init.lua').is_file()):
        parser.error('--engine-root must contain tests/modkit.lua')
    results = []
    for suite in suites:
        if suite.name == 'DoublesDisplayCompatTests.lua':
            results.append({'file': suite.name, 'status': 'not_run',
                            'reason': 'Original cbe1/cbe2/cbe3 producer fixtures are not packaged; '
                                      'no substitute fixtures were fabricated.'})
            print(f'NOT RUN {suite.name}: historical fixtures unavailable')
            continue
        cwd = root
        if suite.name in {'SingleBattleSwitchUITests.lua', 'BattleAudioNativeTests.lua', 'NativeModelCacheTests.lua', 'ReleaseLifecycleCompatibilityTests.lua', 'CacheChoiceConsentTests.lua'}:
            if engine is None:
                results.append({'file': suite.name, 'status': 'not_run',
                                'reason': 'Requires --engine-root with the native Gen1Recomp test fixtures.'})
                print(f'NOT RUN {suite.name}: native engine checkout not supplied')
                continue
            cwd = engine
        start = time.monotonic()
        try:
            process = subprocess.run(
                command + [str(wrapper), str(suite)], cwd=cwd,
                env=env, capture_output=True, text=True, errors='replace', timeout=args.timeout,
                check=False)
            status = 'pass' if process.returncode == 0 else 'fail'
            log = (process.stdout + process.stderr).strip()
        except subprocess.TimeoutExpired:
            status, log = 'timeout', f'Exceeded {args.timeout:g} seconds.'
        results.append({'file': suite.name, 'status': status,
                        'seconds': round(time.monotonic() - start, 3), 'log': log})
        print(f'{status.upper():7s} {suite.name}')
        if status != 'pass':
            print(log)
    counts = {s: sum(r['status'] == s for r in results)
              for s in ('pass', 'fail', 'not_run', 'timeout')}
    print(json.dumps(counts, sort_keys=True))
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps({'runtime': 'love-luajit-dll' if args.lua_dll else ('luajit' if args.luajit else 'texlua'), 'counts': counts, 'results': results}, indent=2) + '\n',
                               encoding='utf-8')
    return 1 if counts['fail'] or counts['timeout'] else 0


if __name__ == '__main__':
    sys.exit(main())
