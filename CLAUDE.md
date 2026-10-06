@AGENTS.md

## API rules

- **Never call customer/storefront endpoints** (`/v1/storefront/...`) from this app. They belong to the customer app, are not meant for tenant/busboy tokens (they answer 401), and the shared `dioProvider` treats a 401 as an expired session and logs the user out. If a tenant/busboy screen needs a field only a storefront endpoint exposes, ask the backend to add it to the tenant/busboy endpoint instead of working around it client-side.

## Target devices

### Tenant device

The tenant app runs on a **Sunmi V2s** (`V2s_STGL`, Android 11) — a handheld POS with a built-in thermal printer and NFC. Design and verify tenant UI against this screen, not the Figma frame size:

- Physical **720 × 1440 px** at **320 dpi** → **360 × 720 dp** logical (devicePixelRatio **2.0**), 18:9 portrait.
- The Figma frames are **390 × 844**, i.e. ~8% wider and ~17% taller than this device. A 16 dp gutter leaves **328 dp** of content width (Figma: 358).
- So anything sized for 358 dp can overflow here. Equal-width tab bars, label + badge rows, and card headers are the usual casualties — scale or wrap instead of clipping text (e.g. `FittedBox(scaleDown)`), and check the narrow case in a widget test (`tester.view.physicalSize = Size(720, 1440)`, `devicePixelRatio = 2.0`, or a 328 px-wide host).

### Busboy device

The busboy app runs on a **Samsung Galaxy Tab S10 Lite 5G** (`SM-X406B`). It is a tablet, so much larger than the Sunmi, and it has **no NFC** — tap-card login is hidden there by design (the login screen only offers it when the device reports NFC). Screen (from the published spec / Google Play Console listing, **not measured on the device** — confirm with `adb shell wm size` / `wm density` when one is connected):

- 10.9", physical **1320 × 2112 px** (16:10), listed density **240 dpi** (hdpi, devicePixelRatio **1.5**) → about **880 × 1408 dp** logical in portrait.
- That is ~2.4× the Sunmi's width in dp, so busboy layouts have plenty of room; the risk there is the opposite one — content stretched across a wide screen (consider capping the content width) rather than overflow.

Don't use the tablet as the reference for tenant layouts; the Sunmi above is the tighter constraint.
