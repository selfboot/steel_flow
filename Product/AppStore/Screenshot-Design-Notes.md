# SteelFlow App Store screenshot design notes

Date: 2026-08-28

## Reference audit

The final deck studies established App Store patterns without copying their artwork:

- [Things 3](https://apps.apple.com/us/app/things-3/id904237743): restrained copy, generous negative space, and real product UI as the proof.
- [Flighty](https://apps.apple.com/us/app/flighty-live-flight-tracker/id1358823008): outcome-first headlines backed by visible, specific data.
- [Arc Search](https://apps.apple.com/us/app/arc-search-find-it-faster/id6472513080): short, oversized benefit statements that remain readable at thumbnail size.
- [Gentler Streak](https://apps.apple.com/us/app/gentler-streak-workout-tracker/id1576857102): one brand system across the full sequence while each frame demonstrates a different feature.

## Layout rule

All six SteelFlow screens use the same information hierarchy:

1. Small feature label.
2. One short, outcome-led headline.
3. One real iPhone screen anchored at the bottom.

The phone no longer alternates between the top and bottom. Continuity comes from the shared blue surface and fixed hierarchy; variation comes from the actual workflow shown inside the device. This prevents decorative layout changes from competing with a technical quoting product.

## Story and evidence mapping

| Screen | Store claim | Matching in-app evidence | Raw asset |
| --- | --- | --- | --- |
| 1 | Steel weight, ready to quote | Profile-based calculation home | `{locale}-home.png` |
| 2 | Dimensions produce weight and cost | Calculated unit mass, total mass, waste-adjusted mass, and subtotal | `{locale}-calculation.png` |
| 3 | Waste, fees, and supplier prices are accounted for | Geometry, material, waste, price basis, unit price, and line fees | `{locale}-pricing.png` |
| 4 | Every steel item rolls into one project total | Three steel items plus mass, fees, markup, tax, and total | `{locale}-project.png` |
| 5 | Client-ready PDF quote | Quote preview with itemized totals and PDF share action | `{locale}-quote.png` |
| 6 | Built-in densities and saved custom prices | Built-in/custom material density list and saved price history | `{locale}-materials.png` |

Both `en-US` and `zh-Hans` use locale-specific names, currencies, suppliers, and quote content. Screens are captured from the real SwiftUI views through a deterministic Debug-only marketing route and UI test.

## Export contract

- Locales: `en-US`, `zh-Hans`
- Screens per locale: 6
- iPhone sizes: 1320×2868, 1284×2778, 1206×2622, 1125×2436
- Final bundle: `Exports/SteelFlow-AppStore-Screenshots.zip`
- Total output: 48 PNG files
