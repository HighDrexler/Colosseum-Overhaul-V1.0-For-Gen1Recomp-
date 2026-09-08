# Validation — CBE 1.8.9-movefx-full.1

Local package validation completed before packaging:

- Every Lua source file parses under Lua 5.3.
- Synthetic WZX validation parses Type-1, Type-4, and Type-6 rows in one dependency-ordered sequence and verifies the Type-6 visibility controller mapping.
- Synthetic serialized GStexture validation verifies the 0x80-byte big-endian header, relative mip pointer, GX format mapping, and RGBA decode path.
- Runtime ownership validation verifies that a complete particle/model/audio/controller/effect chain can own presentation and that one unavailable Type-4 or Type-6 entry rejects ownership for the entire role.
- Controller handler validation verifies Type-1 source-frame delay/stop behavior and Type-6 visibility off/on behavior.
- MoveFX persistent-cache validation now requires index revision 21 and Waza revision 6, matching the extractor that writes the v3 marker.
- Package contains no `.iso`, `.gcm`, `.ciso`, or `.7z` source image.

A real GC6E01 disc and live Gen1Recomp battle renderer are not present in this container, so the authoritative 251-move source audit occurs during the user's fresh MoveFX extraction. The generated `build/movefx_coverage.txt` distinguishes 251/251 source-family discovery from fully executable visual-chain coverage instead of silently treating source presence as implementation completion.
