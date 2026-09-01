# AppSource submission pack — Origo Cloud Events Chat

Everything to submit this app, in one folder. Work top to bottom; each row says where the
text comes from.

**App:** Origo Cloud Events Chat 28.0.0.0
**Prepared:** 2026-09-01

> **Read this first.** CI/CD has failed on every run since 2026-08-29, including `main`, at
> the Build step. Until that is green there is no `.app` to submit. See
> `../AppSource-Readiness.md`.

---

## The short fields, ready to copy

**Offer name** (max 200)

```
Origo Cloud Events Chat
```

**Search results summary** (max 100 — this is the line that shows in marketplace search
results; 85 characters)

```
Ask Business Central questions in plain language and get answers from your live data.
```

**Search keywords** (max 3)

```
AI assistant
Copilot
Chat
```

**Products your app works with** (max 3)

```
Dynamics 365 Business Central
```

The long description lives in `PartnerCenter-Description.md`.

---

## Partner Center, tab by tab

| Tab | Field | Where the text is | Ready? |
|---|---|---|---|
| Offer setup | Offer alias, Name | `PartnerCenter-Listing.md` → Offer setup | ✅ |
| Offer setup | `deliverToAppSource.productId` in `.github/AL-Go-Settings.json` | Paste the product ID once the offer exists | ⬜ you |
| Properties | Categories, industries, terms of use | `PartnerCenter-Listing.md` → Properties | ✅ |
| Offer listing | Search results summary (max 100) | `PartnerCenter-Listing.md` → 84 characters | ✅ |
| Offer listing | Description (max 5 000; keep under 3 000) | `PartnerCenter-Description.md`, the block between the two rules | ✅ |
| Offer listing | Search keywords (max 3) | `PartnerCenter-Listing.md` | ✅ |
| Offer listing | Products your app works with | `PartnerCenter-Listing.md` | ✅ |
| Offer listing | Help link, privacy policy, support URL | `PartnerCenter-Listing.md` → Links. Help link verified 200 | ✅ |
| Offer listing | Support contact, engineering contact | Names, emails, phone numbers — not in this repo | ⬜ you |
| Offer listing | Supporting documents (1–3 PDF) | `AppSource-UserScenarios.pdf` | ✅ |
| Offer listing | Screenshots (3–5, exactly 1280×720 PNG, captioned) | Not made yet. Suggested shots and captions in `PartnerCenter-Listing.md` | ⬜ you |
| Offer listing | Logo (large PNG) | `app/assets/Logo250x250.png` | ✅ |
| Availability | Markets | The 14 in `PartnerCenter-Listing.md`, matching `AppSourceCop.json` | ✅ |
| Technical configuration | App file | Built by `PublishToAppSource.yaml` from `app/` — **blocked by the build failure** | ⬜ |

Phone numbers in Partner Center take digits and spaces only — no dashes, no `+`.

---

## What is in this folder

| File | Use |
|---|---|
| `PartnerCenter-Listing.md` | Field-by-field listing content, with Partner Center's real limits |
| `PartnerCenter-Description.md` | The description text to paste into the rich editor |
| `AppSource-UserScenarios.md` | The scenarios Microsoft's validation team executes — the source |
| `AppSource-UserScenarios.pdf` | The same, rendered. This is the file to upload |

`../AppSource-Readiness.md` sits one level up — the internal assessment, not for submission.
The provider, reverse proxy and Foundry setup guides stay in `../` as well; they are
customer documentation, not part of the offer.

---

## Three things to know before you submit

1. **The build is red.** Every CI/CD run since 2026-08-29 has failed at the Build step.
   Start there — the first thing worth checking is the Core dependency probing path and its
   `GH_CLOUDEVENTS_TOKEN_DEPS` secret.
2. **The Help link is Cloud Events Core's, not this app's.** The URL this app's manifest
   used to advertise returned 404, because no help has ever been published for it. It now
   points at Core's help, which resolves. The permanent fix is in `../AppSource-Readiness.md`.
3. **These texts were rewritten, not adjusted.** The previous versions described a different
   product — "Cloud Events LLM", three providers, a `CE LLM Svc` permission set. Read the
   description before you paste it; the positioning changed from self-hosted-only to six
   providers, and that is a decision worth agreeing with rather than inheriting.

---

## Re-rendering the PDF

No Python on the build machines, so the PDF is printed with headless Edge:

```bash
pandoc AppSource-UserScenarios.md -f gfm -t html5 --standalone --embed-resources --css doc.css -o scenarios.html
```

```bash
"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe" --headless --disable-gpu --no-pdf-header-footer --print-to-pdf="AppSource-UserScenarios.pdf" --virtual-time-budget=10000 "file:///<full-path>/scenarios.html"
```
