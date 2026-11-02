# Independent forward check

Scope: read only the packaged skill.md, readme.md, referenced API/limits note, assets, and adapter script. No board or network access. Outputs are confined to `_skill_work/forward_check`.

## Executed checks

- Ran the README's A command with paths adjusted from `skill/` to the workspace root and output redirected here. Exit 0. `filter_core`, base 1073741824, range 4096, three registers: PASS.
- Ran the equivalent B command. Exit 0. `image_pipeline/pixel_core`, base 2684420096, range 65536, two registers: PASS.
- Created `contract_out_of_range.json` from A with `start.offset = 4096`. A 32-bit register at that offset lies outside a 4096-byte range. Exit 2 with `CONTRACT FAILED: start: offset is not aligned/in the IP address range`. No failure report file was created.
- Both successful reports explicitly say `hardware_access = NONE (metadata validation only)`.

## Conclusions supported

A new user can run the documented offline workflow on an ordinary Python installation without importing PYNQ. The same adapter accepts both supplied synthetic metadata/contracts and rejects a plausible register-range error. This demonstrates configuration substitution and one metadata guard, not operation of two real PYNQ projects. It does not establish register semantics, safe reads/writes, bit/hwh pairing provenance, loaded Overlay identity, hardware functionality, or cross-board compatibility.

## Documentation issue requiring correction

`references/api_and_limits.md` directs the reader to root `templates/board_validation.md`, but that file is absent at the package root, repository root, and `skill/` root. A standalone recipient has no usable board-validation template at the stated location. Package the template and link to a concrete relative location, or replace the reference with an in-document form. This does not block the offline commands; it blocks following the named board-recording step.

## Remaining validation

Run adapter unit/FakeOverlay/FakeMMIO tests to substantiate the README's broader claims; this check did not independently run or establish those claims. For actual projects, obtain their real ip_dict exports and register semantics, prepare corresponding contracts, and rerun offline checks. Before board use, verify the board's installed PYNQ API version and same-build .bit/.hwh provenance. Then perform the documented staged board validation, recording metadata, safe read behavior, explicitly authorized writes/readback, timeout/recovery, and logs. Repeat on the second target if claiming cross-project or cross-board hardware support.

No skill source files were changed.
