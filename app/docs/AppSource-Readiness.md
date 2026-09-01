# AppSource Readiness — Origo Cloud Events Chat

**App:** Origo Cloud Events Chat (`f7a3c6e1-8d42-4b9a-a5e7-3c1d8f4e6b2a`)
**Version checked:** 28.0.0.0
**Repo:** `businesscentralal/origo-bc-cloudevents-chat`, branch `main`
**Checked:** 2026-09-01
**Verdict:** **2 blockers.** One of them is that the app does not currently build.

Findings are measured against **Origo Cloud Events DocEx**, which is live on AppSource and
was published again from `main` on 2026-09-01. Where DocEx does something and this app does
not, that is a gap.

---

## Summary

| # | Severity | Area | Finding |
|---|---|---|---|
| B1 | 🔴 Blocker | Build | CI/CD has failed on **every** run since 2026-08-29, including `main`. The Build step is what fails |
| B2 | 🔴 Blocker | Pipeline | `deliverToAppSource.productId` is empty. DocEx has one |
| F1 | ✅ Fixed here | Help link | Was a 404. Now points at the Cloud Events Core help, which returns 200. Interim |
| — | ℹ️ Note | Object naming | Every object carries the `ori` suffix except `CE Chat Role Prov.`, an enum extension. The house rule does not apply the suffix to extension objects, so this is correct as it stands |
| F2 | ✅ Fixed here | Listing texts | The three submission documents named the app "Cloud Events LLM" and described three providers. There are six |
| W1 | 🟠 Upload | Marketplace media | No screenshots. Partner Center needs 3–5 at exactly 1280×720 |
| W2 | 🟡 Medium | Exposure policy | `resourceExposurePolicy` is fully open here and fully closed in DocEx |
| W3 | 🟡 Medium | Dependency | Core 28.2.2.0 must be live on AppSource before this can be validated |

---

## Blockers

### B1 — The app does not build in CI

**Evidence:** the last eight CI/CD runs, `gh run list --workflow CICD.yaml`:

| Run | Result | Branch | Date |
|---|---|---|---|
| 33336353016 | failure | main | 2026-08-30 |
| 33333525731 | failure | feature/role-provider-migration | 2026-08-30 |
| 33333452527 | failure | feature/role-provider-migration | 2026-08-30 |
| 33329407763 | failure | feature/role-provider-migration | 2026-08-30 |
| 33316293861 | failure | feature/role-provider-migration | 2026-08-30 |
| 33250474924 | failure | feature/role-provider-migration | 2026-08-29 |
| 33250045666 | failure | feature/role-provider-migration | 2026-08-29 |
| 33249902031 | failure | feature/role-provider-migration | 2026-08-29 |

The failing job is `Build . (Default)` and the failing step is `Build`. There is no
successful CI/CD run in that window.

**Why it stops you:** an AppSource submission is a signed `.app` produced by this pipeline.
Until the build is green there is nothing to submit, and nothing in this readiness document
has been validated against a compiled app.

**Fix:** diagnose the Build step. Worth checking first whether it is the dependency probing
path — the app depends on Cloud Events Core `28.2.2.0` and the build pulls Core from
`OrigoSoftwareSolutions/bc-cloudevents` using the `GH_CLOUDEVENTS_TOKEN_DEPS` secret. A
secret that has expired, or a Core version that no longer matches, would fail exactly here
and would explain why every branch fails the same way.

The comparison worth making: the orchestrator, in a different org, builds green against the
same Core.

---

### B2 — The AppSource delivery target is empty

**Evidence:**

| | `deliverToAppSource.productId` |
|---|---|
| Chat | `""` |
| DocEx | `05817eef-3683-41fc-9c00-584f0155bd7d` |

**Fix:** create the offer in Partner Center, paste its product ID into
`.github/AL-Go-Settings.json`. Keep `continuousDelivery: false` until the first manual
submission passes.

---

## Fixed on this branch

### F1 — Help link

`app.json` advertised `.../help/Origo Cloud Events Chat/bc28/en-US/index.html`, which
returns **404**. Like the orchestrator, this repo has no `Help/` folder and no
`PublishHelpToDocsCollection.yaml`, so nothing was ever published there.

| Field | Before | After |
|---|---|---|
| `help` | `.../Origo Cloud Events Chat/bc28/en-US/index.html` → 404 | `.../Cloud Events/bc28/en-US/index.html` → **200** |
| `contextSensitiveHelpUrl` | `.../Origo Cloud Events Chat/bc28/{0}/` | removed |

`contextSensitiveHelpUrl` was removed rather than repointed, so page-level help falls back
to the working Core index instead of a missing page.

**Permanent fix:** add a `Help/` folder and copy `PublishHelpToDocsCollection.yaml` from
DocEx, which publishes to the blob on every push to `main` that touches `Help/**`.

### F2 — The submission texts

The three documents now in `app/docs/appsource-submission/` described a different product:

- They called the app **Cloud Events LLM**. `app.json` says **Origo Cloud Events Chat**, and
  the install scenario told a validator to search the marketplace for the wrong name.
- They described **three** providers. `CEChatRoleProv.EnumExt.al` registers **six**: OpenAI,
  Azure OpenAI, Custom LLM, Anthropic, xAI (Grok) and Google (Gemini).
- They referenced a `CE LLM Svc` permission set. The real ones are `CE Chat Svc ori` and
  `CE Chat Obj ori`.
- The listing claimed a 50-character limit for the search summary (it is 100) and listed
  **twelve** keywords against a maximum of three.
- `app.json`'s own `description` also listed four providers; it now lists all six.

The scenarios were rewritten and extended from 11 to 13 to cover error handling and
permission verification, both of which Microsoft requires and neither of which was present.

---

## Open

### W1 — Screenshots

`app.json` has `"screenshots": []` and the repo holds no images beyond the logo. Partner
Center requires 3–5, each exactly 1280 × 720 PNG, each captioned. Suggested shots and
captions are in `appsource-submission/PartnerCenter-Listing.md`.

For this app in particular, a short video of a question and its answer would sell it better
than three still images. Partner Center takes up to four, hosted on YouTube or Vimeo.

### W2 — Source exposure

| | `allowDebugging` | `allowDownloadingSource` | `includeSourceInSymbolFile` |
|---|---|---|---|
| Chat | true | true | true |
| DocEx | false | false | false |

Both are legal for AppSource, but the app Origo already sells ships with source download
off. Decide deliberately.

### W3 — Dependency

`app.json` requires Cloud Events Core 28.2.2.0. Microsoft installs dependencies from the
marketplace, so Core must be live at that version or later before this offer can be
validated.

---

## What passed

- `app.json` carries every field validation checks for: `privacyStatement`, `EULA`, `help`
  (now resolving), `url`, `logo`, `brief`, `description`, `applicationInsightsConnectionString`,
  `supportedLocales`, `target: Cloud`, `application` and `platform` at 28.0.0.0.
- `AppSourceCop.json` already declares all 14 `supportedCountries` — the orchestrator does
  not, so this app is ahead there.
- Permission architecture is sound, and better than the orchestrator's: `CE Chat Obj ori`
  grants every object including the setup wizard page, `CE Chat Svc ori` gates the shared
  service key separately, and `CE Chat Full ori` / `CE Chat Read ori` extend Core's own role
  sets so existing customers need assign nothing new.
- API keys are held in isolated storage, per user or company-scoped, and are not readable
  back through the UI.
- Request logging redacts bodies unless debug mode is on.
- Translation file: 89 units, no `needs-translation`.
- A test app exists with 37 test procedures.
- Every object ID falls inside the declared range (10 035 485 – 10 035 534).

---

## What I could not check

- **Anything that requires a build.** See B1 — CI has not produced a green build since
  2026-08-29, and the app was not compiled locally either (no Core 28.2.2.0 symbols on the
  machine these documents were written on). CI is the authority.
- **Runtime behaviour.** No sandbox, so none of the scenarios have been executed. They were
  written from the AL source and from the previous scenario document, with the provider
  list, permission set names and page names checked against the code.
- **Core's marketplace status** (W3).
