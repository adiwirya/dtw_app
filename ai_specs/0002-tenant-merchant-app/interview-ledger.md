---
type: Interview Ledger
parent: ./spec.md
---

# Interview Ledger — DTW Order (Tenant / Merchant)

Source: `/ftk-figma-plan` on Figma file `CPWCfPomucIUq4k7hZwtwM`, page 🟡 HIFI Tenant (632:10585).

| ID | Question | Resolution | Status |
|----|----------|------------|--------|
| L1 | Which flavor does this design target? | **Tenant** (merchant/seller side of DTW Order), per command args. | current |
| L2 | Harvest scope for the 34 tenant frames? | Approved **full harvest of all 34** via figma-cli Safe Mode. All cached (reference.png + values.json + tree.txt). `laporan` (390×3402) cached at `reference@0.5x.png` — @1x exceeded the export transfer buffer. | current |
| L3 | How do Tenant and Busboy coexist (shared login has Tenan/Busboy role cards; both build into the same `dtw_app` project where busboy already exists)? | **Separate build flavors** — a tenant product-flavor entrypoint (`main_tenant.dart`) with its own shell/router, separate from the busboy app. | current |
| L4 | Work Item granularity? | **Grouped by feature (8 items)** — tab/state variants collapse per feature area. | current |
| L5 | Screen-to-screen flow? | **Real prototype reactions** via figma-cli (`source: "prototype"`, 57 edges in `manifest.json`). 4-tab bottom nav: Order (Home) / Menu Saya (Search) / Laporan (Imagine) / Admin (Message). Login is 2-step (`login-default` → tap Tenan → `login-tenantt` → Masuk → `menu-order-baru`). | current |
| L6 | Tenant-specific requirements (from the on-canvas design note 911:11245)? | Captured verbatim as design intent driving Menu/Variant items: order **reject-per-item**; "best seller" → **PIN/Popular**; **promo removed**; **2 discount fields** (percentage + price + valid date); **stock availability removed**; customization options **required + multi-select**; **"+price"** on options (e.g. spicy). Data/validation specifics remain Open Questions. | current |
