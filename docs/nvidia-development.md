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

Local pre-launch checks on RTX 4080: GPU suite 122 passed / 4 ignored; shader suite 274 passed / 6 ignored / 4 failed. All four shader failures reproduce on the unmodified Belobug base (two wave64 pipeline refusals and two split-wave divergent scalar counts). They remain tracked limitations, not passing checks. The sparse-texture GPU readback, actual hardware FPS-overlay execution, and pipeline priority regressions pass. The first scene run was stopped after confirming a 500 ms pipeline-wait regression; active-use priority is the next runtime validation.


### Startup follow-up

The initial RTX launch fast-failed in `nvwgf2umx.dll` (0xc0000409, parameter 2). A local dump's call stack led to `Presenter::readout`. Disabling the FPS overlay survived the failing startup point; recording the glyph rectangles in batches of 16 now passes a real hardware GPU execution test. The launcher conservatively disables the overlay while retaining caption/log measurements. Menu frames spent 500 ms waiting for a shader behind background prewarming; first-use pipeline jobs now overtake warmups without duplicate compiles. These are separate fixes from texture residency.

### Texture and NVIDIA correctness follow-up

Integrated Belobug PRs [181](https://github.com/Belobug/VIctory-Belobug-AMD/pull/181) (BC7 dictionary), [201](https://github.com/Belobug/VIctory-Belobug-AMD/pull/201) (dynamic descriptor run crossing the cursor), [197](https://github.com/Belobug/VIctory-Belobug-AMD/pull/197) (capture/probe lifetime), [179](https://github.com/Belobug/VIctory-Belobug-AMD/pull/179) (64 KiB watch epochs), the regression from [203](https://github.com/Belobug/VIctory-Belobug-AMD/pull/203), the shader portion of [68](https://github.com/Belobug/VIctory-Belobug-AMD/pull/68), and [158](https://github.com/Belobug/VIctory-Belobug-AMD/pull/158) (NVIDIA handled compiler exceptions). The capped-heap portion of 68 was already covered here. Cherry-picks preserve original authors. The locally diagnosed overlay fix overlaps the independently published [185](https://github.com/Belobug/VIctory-Belobug-AMD/pull/185); no duplicate contribution is being submitted for it.

A forced-overlap test reproduced prewarm overwriting upload memory still read by the previous asynchronous GPU submission. Removing those early writes fixes its synchronous and asynchronous controls. Shared upload refresh now happens after completion; CPU command recording can still overlap the GPU. Before PR68, four existing shader regressions failed on both this fork and untouched Belobug. After PR68, all four pass: the complete shader suite is 283 passed / 0 failed / 6 ignored, plus 3 integration tests passed / 1 ignored. The preceding combined suite was GPU124 passed / 5 ignored and formats25 passed / 4 ignored; the ignored overlap regression also passed explicitly after the fix.

The be40f12 game run recovered the menu/loading-art frame rate (up to60 FPS menus; about30 FPS loading art) and survived the overlay crash point, then exited with0x887A0005 around the transition to the world. That executable predates the correctness follow-up. World texture coverage and stable30 world FPS remain unverified. The NVIDIA launcher sets VICTORY_COMPILER_GUARD=0 so driver-handled first-chance faults do not park compilation or reuse a false pipeline blacklist.
