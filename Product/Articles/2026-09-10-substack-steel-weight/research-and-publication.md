# Substack research and publication status

Research date: 2026-09-10. Target: English-speaking readers estimating steel material quantities and costs.

## Keyword evidence

Provisional primary keyword: **steel weight calculation**. Secondary phrases: **flat bar weight per metre**, **steel plate weight**, **steel weight calculator**.

These are relevant to the tutorial, but **country-specific Google monthly search volume has not been verified**. The title is provisional pending keyword-volume validation. Do not describe these as proven high-volume or low-competition keywords.

Queries checked included `"steel weight calculator" "search volume"`, `"steel plate weight calculator" "monthly searches"`, `"steel weight calculator" "Volume" "semrush"`, and `"steel weight calculation" "keyword"`. Public results mostly described calculators, not keyword data.

- https://www.clonick.com/niches/ reports “Steel weight” at 27,100 searches/month. It does not expose the exact query, country, measurement period or data source. This is a third-party unverified claim and is **not** adopted as a verified number for this article.
- https://ahrefs.com/keyword-generator provides Google keyword estimates by country. Its tool landing page was accessible, but the interactive query was not completed because computer control lost access to the Chrome window.
- Google Trends explore was attempted with steel weight calculator and steel weight calculation; the web tool could not retrieve it. No Trends values were obtained. Trends indices, even if later obtained, are relative interest rather than absolute monthly search counts.

Search result supply / competitor content (not volume evidence):

- https://www.omnicalculator.com/construction/steel-weight — calculator plus formula explanation, worked computation and FAQs.
- https://www.navrangsteel.com/weight-calculator/ — supplier tool uses related phrases around plate, bar and mild steel weights; vendor keyword placement is not independent demand proof.

Editorial choice: answer the informational formula intent in the title and opening. Mention a steel weight calculator naturally later, without implying that this Substack page contains an interactive calculator. Add plate and flat bar examples, then costs and PDF quote checks. Link the already-published Medium delivery-cost comparison rather than reproducing its whole structure.

## Article and images

- article.md: complete local English draft, approximately 1,200 words.
- index.html: local preview with all three images referenced successfully.
- seo.json: provisional title, subtitle, description, slug and keyword status.
- Images reuse verified real app captures from ../2026-09-10-compare-steel-prices/. Includes single calculation, six-screen montage and PDF preview.
- Same density and flat bar example as the existing article. Added plate calculation: 1 m × 2 m × 10 mm at 7,850 kg/m³ = 157 kg.
- Basic arithmetic and local image references checked by script. New HTML desktop/mobile visual review is **pending** because browser control became unavailable.
- Full English and Chinese App Store names, regional detail links and search fallback are present.

## Substack status

The signed-in profile is `puzzles`, publication host `puzzlesgame.substack.com`. Opened Create → Article and reached:

https://puzzlesgame.substack.com/publish/post/215053669

**Not published. No article body or images have been entered into Substack.** An editor URL exists, but its contents could not be inspected after the window became inaccessible.

Native CUA returned empty accessibility trees and no screenshots. Reconnecting the app did not restore access. Extension getTab also timed out. Asked the user to keep the Mac unlocked and Chrome available. Do not mistake the existence of the editor URL for a saved full draft or successful publication.

Next steps when computer access resumes:

1. Query Google keyword estimates (record country, period, source and date; compare informational variants). Adjust provisional title if evidence warrants it.
2. Enter the local article, upload the three real images, set captions/alt, review layout and links.
3. Use public/everyone audience and web-only delivery; do not send email/app notifications unless separately requested.
4. Set slug and SEO description if the editor exposes them. Publish and inspect the public article and images; record canonical URL.

Official Substack publishing instructions: https://support.substack.com/hc/en-us/articles/360037831771-How-do-I-publish-a-new-post-on-Substack (updated June 9, 2026). It states posts default to web + email/app inbox and the delivery box can be unchecked for web-only publishing.

## Follow-up retry on 2026-09-10

User clarified Medium had worked without unlocking. Do not attribute this failure to lock screen without evidence. Native Chrome reconnected and exposed the editor. Title and subtitle were entered and their exact values verified in AX; body remains `Start writing...`. HTML paste failed with application clipboard-read timeout. Native direct body setValue had no verified effect. Extension getTab failed `Debugger unattached`; fresh tab 687920159 was created for the same draft but its getTab failed likewise. No images uploaded and no publication attempted. Local article remains intact. The concrete blocker is unreliable browser control, not proven login/lock-screen requirements.

## Retry after user opened editor, 2026-09-11

Fresh user tab 687920166 points at the same draft. Title, subtitle and initial paragraph persist. Native control again returned noWindowsAvailable; getTab on the fresh tab timed out and reset the kernel. A numbered-list toolbar state was briefly reported after an attempted body selection, while the screenshot did not corroborate it; review first-paragraph formatting on recovery. No full-body paste, images or publish action completed. Repeatedly asking the user to click the page is not a demonstrated fix.

## Latest requested publication attempt

Full formatted article is now present in the Substack draft, including captions and correct regional App Store links, apparently from the user's paste. Three image blocks show IMAGE NOT FOUND. Native coordinate click failed noWindowsAvailable; extension connection failed Debugger unattached again. A later native action produced an inconsistent state including an extra literal IMAGE NOT FOUND after the flat-bar paragraph; Undo was sent, but restoration could not be conclusively checked. Review this area and title formatting on recovery. No image upload or publish action completed.

## Control diagnosis and recovery, 2026-09-11

- Confirmed the extra literal IMAGE NOT FOUND after the flat-bar paragraph was absent on subsequent inspection. Three broken image blocks still require replacement. Draft reported Saved before Chrome restart.
- Restarted SkyComputerUseService and completed Chrome's pending update through its UI. Found two orphaned headless Chrome sessions from this project's previous screenshot jobs (`steelflow-en`, `steelflow-en2`), sharing com.google.Chrome with the visible browser. Gracefully stopped only those two Chrome processes and their two orphaned Playwright daemon parents; preserved the regular visible browser.
- Same-bundle process ambiguity is a plausible cause of reads targeting the visible window while actions report noWindowsAvailable; this is a diagnosis from observed process state, not a confirmed internal implementation fault.
- After resetting control sessions and removing those stale processes, native reload, address navigation, login-button click, saved-email selection and Continue worked with matching accessibility state. No new noWindowsAvailable occurred in these checks. Image-upload validation remains pending.
- The draft URL initially returned Unable to load post, then ERR_TOO_MANY_REDIRECTS. Substack homepage loaded normally but required login. No cookies were cleared. Login using the browser's saved email reached the explicit magic-link/code screen: Substack says it sent a login email to xuezaigds@gmail.com. Waiting for the user's code or magic-link completion; no credentials extracted.
- Article remains unpublished, images not yet uploaded, and Google monthly search-volume estimates still unverified.

## Successful login and image repair, 2026-09-11

- User supplied the login code; login succeeded as puzzles. Returned to existing draft 215053669.
- Uploaded all three PNG files through native Chrome file dialogs with Computer Use. Removed each original IMAGE NOT FOUND block after inserting its replacement. Preview accessibility now contains three Substack CDN image links and no broken-image text. Calculation screenshot, six-screen montage and quote preview were each visibly rendered; montage and quote were opened in the mobile preview lightbox. Captions remain intact.
- Checked visible title (no literal Markdown asterisks), full app names, US and China App Store links. Draft reported Saved. Regional URLs are unchanged from prior verified links.
- Opened Publish. Audience Everyone; comments Everyone. Unchecked Send via email and the Substack app (confirmed value 0), schedule unchecked. Created Steel weight calculation tag. Publish now button was visible, but was NOT clicked.
- Next native key action returned explicit: Mac is locked and automatic unlock could not unlock it. Await manual unlock, then inspect fresh publish settings and finish authorized web-only publication. This is a new explicit lock condition, distinct from earlier inferred process conflict. Article remains unpublished. Google monthly keyword-volume data still unverified.
- CDN image IDs: calculation 0dba064c-deef-4661-a32c-a6d4d24f1bfe; montage 0a679277-339a-45e0-9291-bb17b04ad200; quote 8c314f30-ad68-4e99-a4e0-6d5d03fd9caf.
