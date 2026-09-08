# CBE 1.9.5-information-ui-idle.1

Information-viewer animation correction rebased directly on 1.9.4. PC/Pokédex/Summary actors retain first-pixel compact-scene rendering and resident cache reuse, but now always upgrade to an available source-authored idle bank after the initial frame instead of assuming any base morph frames constitute a valid idle loop. No arena, battle camera, MoveFX, capture, trainer, or audio behavior is intentionally changed.
