# NVIDIA experimental integration

Base: Belobug/VIctory-Belobug-AMD `4f62c2a5e27e7beebf3e8d68f77898e43dc7b77c`.

## Changes

- Probe the physical descriptor limit before translation, clamp generated indices to it, include it in shader-cache keys, preserve requested small heap sizes on capped hosts, and retain a dedicated final null slot.
- Hash the translator's source and switches at build/run time with a relocatable build script. Rebuilding a launcher alone does not discard unchanged translations.
- Admit readable interior texture pages, upload through the existing safe zero-filled read path, and choose resident mip prefixes before allocating host copies. Rewrites bypass hash and write-watch backoff.
- Keep valid-but-unmapped placed textures in a bounded rotating recovery queue rather than dropping them until an unrelated descriptor change.
- Adapt scalar UINT lighting-mask and typed-buffer reads from DexNom `b8ff22e4c8fe083679849f72ba1ed3451cc24c67`, scoped by the original container digest, root field, and resource kind.
- Retry the existing exact empty-EXEC control-flow rewrites before reporting an unsupported NVIDIA wave64 shader. Larger group exchanges remain limited; no globally unsafe wave-wide switch is enabled.
- Adapt DexNom's bounded best-fit snapshot pool and fxceless `c36971b213770e48f513f0d6e3ced3f1f65a32b2` byte-mask comparisons. Preserve CPU/GPU merge conflict semantics. Add the optional KiB threshold for small device-local buffer copies.
- Retain Belobug's sky-following indirect-light approximation and view-based mip trimming. These are the new base's equivalent paths; the old NZX tiled-resource implementation was not substituted into this different texture architecture.
- Load BCPack tables from a local sidecar instead of embedding them in distributable binaries.

## Attribution

Belobug and all VIctory contributors retain their existing credit and history. The material/typed-view and snapshot-pool adaptations above derive from DexNom's GPL-3.0-or-later source. Vector byte comparison and small-buffer threshold ideas/code derive from fxceless/victory-fork under GPL-3.0-or-later. Empty-EXEC rewrites derive from the earlier VIctory integration. No game assets, shader containers, saves, captured images or raw title logs belong in a public release.

## Validation

Regression tests, compilation, offline shader validation, and the RTX 4080 scene result are recorded in release notes. A successful test suite does not establish complete game rendering. This branch remains experimental; reviewers should assess the individual commits before upstream integration.

Local pre-launch checks on RTX 4080: GPU suite 119 passed / 4 ignored; shader suite 274 passed / 6 ignored / 4 failed. All four shader failures reproduce on the unmodified Belobug base (two wave64 pipeline refusals and two split-wave divergent scalar counts). They remain tracked limitations, not passing checks. The new sparse texture GPU readback regression is pending execution; game validation takes priority for this iteration.
