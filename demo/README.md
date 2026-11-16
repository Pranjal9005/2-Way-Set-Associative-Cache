# Prototype Demo Video

**Video link:** _to be added after upload (YouTube unlisted or Google Drive, set to "Anyone with the link")_

Coordinator: Nikith Gowda B S (Documentation and Repository)

## Requirements (Phase I, 15 marks)

- [ ] Length **5 minutes or less**
- [ ] Project idea stated clearly
- [ ] **All 5 members** introduce themselves by name
- [ ] Working prototype shown: Verilog, block diagram, simulation output, waveforms
- [ ] Link added to this file **and** to the main [README](../README.md)
- [ ] Link submitted through the course form

## Shot plan (about 4:45)

| Time | Segment | Speaker | What is on screen |
|---|---|---|---|
| 0:00–0:30 | Team intro and project idea: a 2-way set-associative cache with LRU replacement, in Verilog | All 5 (about 6 s each) | Title slide with names |
| 0:30–1:15 | Architecture: 4-bit address (tag = A[3:1], set = A[0]), 2 sets × 2 ways, module overview | Pranjal | `diagrams/block_diagram.svg` |
| 1:15–1:50 | Storage and decoding: `cache_array`, valid bits, `address_decoder`, `tag_comparator` | Ritesh | `rtl/cache_array.v`, `rtl/address_decoder.v` |
| 1:50–2:30 | LRU logic: one bit per set, hit/invalid/LRU way priority, eviction example 3, 5, 3, 7 | Meghna | `rtl/lru_unit.v`, `rtl/hit_miss_unit.v` |
| 2:30–3:15 | Controller FSM: IDLE → LOOKUP → (hit) RESPONSE, or (miss) MEM_READ → WAIT_MEM → FILL → RESPONSE | Pranjal | `diagrams/controller_fsm.svg` |
| 3:15–4:15 | Live simulation: run `cache_2way_tb` (53/53 pass), show hit/miss and LRU eviction in the waveforms | Shreya | Terminal + GTKWave |
| 4:15–4:45 | Results (conflict pair 0 % → 87.5 %), repository walkthrough, report | Nikith | README on GitHub, report PDF |

## Commands to show on screen

```bash
# from the repository root
iverilog -g2012 -s cache_2way_tb -o cache_2way_tb.vvp rtl/*.v testbench/cache_2way_tb.v
vvp cache_2way_tb.vvp
```

## Editing checklist

- [ ] Clear audio for every speaker; captions with each member's name the first time they speak
- [ ] Code and terminal font large enough to read at 1080p
- [ ] Final export is 5:00 or less (check the length before uploading)
- [ ] Upload, set the link to be viewable by anyone with it, and test it in a private browser window
