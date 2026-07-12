---
type: Interview Ledger
parent: ./spec.md
---

# Interview Ledger — DTW Order (Busboy)

Source: `/ftk-figma-plan` on Figma file `CPWCfPomucIUq4k7hZwtwM`, page 🔴 HIFI Busboy (624:1670).

| ID | Question | Resolution | Status |
|----|----------|------------|--------|
| L1 | Which flavor does this design target? | **Busboy** (courier side of DTW Order), per command args. | current |
| L2 | Harvest scope for the 17 screens? | Approved full harvest of all 17. First attempt via Figma MCP hit the Starter-plan quota after 5 calls; **re-harvested via figma-cli** (Safe Mode plugin — Yolo/CDP could not reach the `figma` API in this Figma build). **All 17 screens now fully cached** (reference.png @1x + values.json + tree.txt). | current |
| L3 | Work Item granularity? | **Grouped (12 items)** — tab/state variants of one route collapse into a single Work Item, rather than one item per frame. | current |
| L4 | Manual-export blocker on screen items? | **Obsolete.** The figma-cli harvest completed the cache, so the "manual export required" Blocking Decisions were removed from items 03–12. | current |
| L5 | Screen-to-screen flow? | **Real prototype reactions** extracted via figma-cli (`source: "prototype"`, 42 edges in `manifest.json`). Corrected the earlier inference: login is a **2-step** flow (`login-default` → tap role → `login-tenantt` → *Masuk* → `menu-order-baru`); the two success modals lead to `menu-order-antar` / `menu-order-selesai`. | current |
