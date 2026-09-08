# Validation — CBE 1.9.1-bite-source-layout.1

- Reparsed the installed GC6E01 `kamituku` attack, damage, and `tatsubay` WZX
  members using parser 8: 4/4 rows complete in every phase.
- Ran those retained source members through extractor 24 with an isolated cache:
  attack ready, damage ready, full visual ready, three HSD models, six GPT1
  programs, and zero unsupported entries.
- Regression tests cover Type-2 HSD sizing, Type-3 direct GPT1 and embedded-HSD
  layouts, damage-role classification, and incomplete-timeline rejection.
- All Lua sources load under embedded Lua 5.4 and the packaged test suite passes.
- Protected BGM/MusyX/Amuse production files remain byte-identical to the
  1.8.9-audio-source-recovery.1 baseline.
