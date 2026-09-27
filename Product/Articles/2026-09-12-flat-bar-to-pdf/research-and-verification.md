# Research and verification — 2026-09-12

## Editorial decision

Primary intent: flat bar weight calculator, with a complete known-dimension order-to-PDF workflow. Target readers: small workshops and buyers preparing a material quote. Specific secondary phrases: 100 x 10 flat bar weight per metre, steel flat bar weight formula, metal quotation PDF.

This differs from the previous pricing-basis comparison and general feature introduction. No verified keyword volume, traffic estimate or ranking promise is available.

## Sources and evidence

- https://www.reddit.com/r/estimators/comments/1u0l662/steel_faberection_estimators_what_is_the_software/ — user discussion of steel estimating tools and spreadsheet flexibility; relevant to keeping inputs organized, not proof that this app replaces full fabrication/erection estimating.
- https://www.reddit.com/r/StructuralEngineering/comments/1kwo8rc/steel_profile_calculator_i_made_now_live_in/ — the original post promotes another calculator. A reader reports inability to use it on a mobile browser and says on-site quick reference would be useful. This is a narrow user-reported mobile need, not a market-size estimate.
- https://parksidesteel.co.uk/tools/steel-weight-calculator — supplier's calculator/tutorial explains profile inputs, per-piece length, quantity, nominal density and theoretical versus actual weights. Useful formula and workflow reference. This article adds a reproducible single-order project/PDF walkthrough; no copied prose or images.
- https://steelmath.com/weights/100x10-flat-bar-weight — search-result evidence of the exact 100 x 10 flat-bar topic. Search supply does not establish demand volume; not used as the technical authority.
- https://help.medium.com/hc/en-us/articles/22576852947223-Artificial-Intelligence-AI-content-policy — disclose AI-generated prose within the opening paragraphs; do not publish this story behind a Partner Program paywall. No promise of general distribution.

## Capture method

Current production SwiftUI views and calculation/PDF services are used in an isolated source copy at /tmp/steelflow-flatbar-article-20260912. The current app source directory is not edited. Demo seeding uses CalculatorDraft.makeItem, matching the save workflow's item construction. The isolated copy changes demo input values, single-project fixture, and DEBUG initial scroll/expanded state only. This is authentic simulator UI with seeded data, not evidence of an automated end-to-end tap test.

Case: carbon steel, plate/flat bar, width 100 mm, thickness 10 mm, length 6 m, quantity 18, density 7850 kg/m³, USD 0.74/kg. Waste/fees/markup/tax zero. Project Flat Bar Order, Q-FLAT-10010, Demo Workshop. Data is fictional; no live supplier pricing.

Independent expected values: area 0.001 m²; one-piece volume 0.006 m³; 7.85 kg/m; 47.1 kg/piece; total 847.8 kg; USD 627.372 before currency rounding, USD 627.37 after rounding.

## Publication

Not published. Medium browser connection via CUA timed out. The available dedicated browser opened https://medium.com/m/signin; user asked to log in. Verify account and continue with a new article when authenticated; do not overwrite earlier drafts.

## Completed checks

- Source commit 594d301, version 1.1.0 (13). Isolated build succeeded.
- App-generated snapshot asserts 18 pieces, 47.1 kg each, approximately 847.8 kg total (floating-point storage), currency-rounded USD 627.37. Decimal calculation independently matches.
- Full original PDF text and rendering checked: Q-FLAT-10010, Demo Workshop, flat bar 100 x 10 mm, length 6 m, quantity 18, mass 847.8 kg, total $627.37, tax $0.00, one page. The free PDF excludes custom terms and company header; article wording corrected and quote screenshot recaptured using --workflow-free.
- All four original screenshots reviewed; four-screen montage, both two-screen layouts, and PDF crop checked visually. Original PDF and full-page render retained. No AI-generated UI.
- Browser QA: desktop 1280 px and mobile emulation 390 px have no horizontal overflow; all four images load. Readable heading and paragraph layout; screenshots can be opened at full resolution from the HTML preview.
- US App Store link opened the actual SteelFlow: Metal Calculator detail page in the browser on 2026-09-12. Version 1.1.0 and feature/pricing model verified from visible listing. China link was previously verified; not rechecked in this turn. Web verification does not guarantee phone storefront handoff.

## Remaining

Medium sign-in, new draft creation, native image uploads, final published-page review and public URL. The story has not been published. No Partner Program paywall should be enabled.


## Publication completed

Published using the user's signed-in local Chrome account @xuezaigds. URL: https://medium.com/@xuezaigds/flat-bar-weight-calculator-from-100-x-10-mm-steel-to-a-pdf-quote-2106816446e0

The public page and success dialog were verified. Four native images, five numbered step headings and both App Store links are present. Topics: Manufacturing, Steel, Metalworking, iOS. Email notification disabled; article is not paywalled. Final browser text uses ASCII multiplication x and spells out square/cubic metres for reliable native input; the verified numbers are unchanged. The screenshot montage and PDF-detail image have captions; all UI screenshots identify simulator/demo provenance in their artwork and opening disclosure. Earlier sign-in/pending notes above describe historical workflow state.
