# Validation — CBE 1.9.0-movefx-source-chain.1

Local validation completed before packaging:

- All 58 Lua sources load under an embedded Lua 5.4 runtime.
- Source-chain tests verify forward entry-link timing, explicit missing-anchor diagnostics, incomplete-phase ownership rejection, mandatory Type-4 texture rejection, and artifact contracts for all thirteen Type-4 families.
- The complete-cache marker and index gate require extractor 23, Waza parser 7, source discovery 251/251, and executable visual chains 251/251.
- The builder requires the GC6E01 `common_rel.fdat` move table and stores the two animation selectors for every move row in `cache/movefx/index.lua`; WZX discovery begins with the selector-selected bank and persists the resolved source stem.
- MoveFX-only changes were checked to exclude `PortableMusyX.lua`, `WazaSfxBuilder.lua`, `AudioWorker.lua`, `AudioProbe.lua`, `Music.lua`, and the bundled Amuse renderer.
- The package contains no `.iso`, `.gcm`, `.ciso`, or `.7z` source image.

A GC6E01 disc and live Gen1Recomp renderer are not available in this workspace. The authoritative per-move extraction and Windows/Android visual comparison therefore remains a required on-device validation. The retail DOL's per-species PKX body-motion dispatch also remains unproven; source-Waza attacks deliberately hold the base body pose instead of displaying a guessed generic action. Any visual-chain failure must appear in `build/movefx_coverage.txt`; the build will not write a complete MoveFX marker for partial coverage.
