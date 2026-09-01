# Partner Center listing — Origo Cloud Events Chat

Field-by-field content for the offer. Limits are Partner Center's own, from the Business
Central offer listing documentation (2025-07-28 revision).

**Offer status:** not created yet. `deliverToAppSource.productId` in
`.github/AL-Go-Settings.json` is empty and must be filled in once the offer exists.

> The previous version of this file called the app **Cloud Events LLM** and listed twelve
> keywords. The app is **Origo Cloud Events Chat** (`app.json`), and Partner Center accepts
> at most three keywords. Both are corrected here.

---

## Offer setup

| Field | Value |
|---|---|
| Offer alias (internal) | origo-cloud-events-chat |
| Offer name (≤ 200 characters) | Origo Cloud Events Chat |

---

## Properties

| Field | Value |
|---|---|
| Primary category | Productivity |
| Secondary category | IT & Admin Tools |
| Industries | Professional services, Financial services, Retail, Distribution, Manufacturing |
| App version | 28.0.0.0 |
| Terms of use | https://www.origo.is/skilmalar-og-oryggismal |

---

## Offer listing

### Search results summary (≤ 100 characters)

```
Ask Business Central questions in plain language and get answers from your live data.
```

85 characters.

### Description (≤ 5 000 characters; keep under 3 000)

See [PartnerCenter-Description.md](PartnerCenter-Description.md). Paste the block between
the two rules in that file.

### Search keywords (maximum 3)

1. AI assistant
2. Copilot
3. Chat

The earlier list of twelve was over the limit. If these three feel wrong, pick any three —
but three is the ceiling, and they should also appear in the description text.

### Products your app works with (maximum 3)

1. Dynamics 365 Business Central

### Links

| Field | Value | Rule |
|---|---|---|
| Help link | https://origopublic.blob.core.windows.net/help/Cloud Events/bc28/en-US/index.html | The Cloud Events Core help. Verified 200. Interim until this app publishes its own — see `../AppSource-Readiness.md` |
| Privacy policy link | https://www.origo.is/um-origo/stefnur/personuverndarstefna | Must be a working privacy policy |
| Support URL | https://www.origo.is/ | Must differ from the Help link |
| Support email | bc-support@origo.is | The address DocEx lists |

The Help link and the Support URL cannot be the same value — Partner Center rejects that.

### Contact information

| Contact | Needed |
|---|---|
| Support contact | Name, email, phone, support website URL |
| Engineering contact | Name, email, phone |

Not shown to customers. Phone numbers take digits and spaces only — no dashes, no `+`.

**To fill in before submission** — neither contact is recorded in this repository.

---

## Supporting documents (1–3, PDF)

`AppSource-UserScenarios.pdf` in this folder. That is what Cloud Events DocEx submitted, and
it is the one to upload if you upload only one.

---

## Marketplace media

All images must be PNG. Blurry images are rejected.

### Logo

`app/assets/Logo250x250.png` exists and is referenced from `app.json`. Upload it as the
large logo; Partner Center derives the other sizes.

### Screenshots — 3 to 5 required, each exactly 1280 × 720 PNG, each captioned

**Missing.** Reuse the set from the Cloud Events Core offer if the chat panel appears in
them; otherwise capture three of this app:

| # | Screen | Caption |
|---|---|---|
| 1 | The chat panel open on a Business Central page, mid-answer | Ask a question on any page and get an answer from live data |
| 2 | Chat role card with provider and model configured | Choose a provider per role — commercial, Azure, or your own model |
| 3 | Setup wizard | A wizard gets outbound requests and the first provider running |

DocEx's convention is a tracked top-level `screenshots/` folder with numbered names
(`01-…`, `02-…`, `03-…`), which keeps the offer rebuildable from the repo.

### Videos (optional, up to 4)

A short screen recording of a question and answer would carry this app better than the
screenshots do. Host on YouTube or Vimeo, with a 1280 × 720 PNG thumbnail.

---

## Availability

Markets to select — these match `supportedCountries` in `app/AppSourceCop.json`, which
already declares all 14:

Iceland, United Kingdom, Denmark, Norway, Sweden, Finland, Germany, France, Netherlands,
Austria, Switzerland, Ireland, Portugal, Spain.

---

## Technical configuration

| Field | Value |
|---|---|
| App file | Built by AL-Go `PublishToAppSource.yaml` from `app/` |
| Dependency | Origo Cloud Events Core 28.2.2.0 — **must already be live on AppSource** |
| Test app | `test/` — not submitted, referenced by `internalsVisibleTo` |

---

## Before you paste any of this

Two things on this page are not done: the three screenshots and the two contact blocks. The
help link now resolves. `../AppSource-Readiness.md` lists what is left outside this page.
