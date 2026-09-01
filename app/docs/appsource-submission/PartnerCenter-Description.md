# Description text — Partner Center rich editor

Paste the block below into **Offer listing → Description**. Partner Center allows up to
5 000 characters; Microsoft's Business Central readiness guidance recommends staying under
3 000.

Basic HTML is allowed in that field — the headings and lists below are written so they can
be pasted as plain text or marked up without rewriting.

---

**Origo Cloud Events Chat** puts an AI assistant inside Business Central that can read your
live data. Users ask a question in plain language on any page, and the model answers by
calling tools against the actual database — under that user's own permissions, never
outside them.

### Who it is for

**Business users** who want answers without building a filter or finding the right report:
customer balances, open orders, inventory levels, posting status.

**IT teams and administrators** who need to decide where inference happens. Point the app at
a commercial provider, at Azure OpenAI in your own tenant, or at a model running on your own
hardware — the choice is configuration, not a different product.

**Organisations with data residency requirements** that rule out sending business data to a
public AI service. A self-hosted endpoint keeps every request on your own network.

### Six providers, one configuration

| Provider | Typical use |
|---|---|
| OpenAI | Commercial models, Bearer authentication |
| Azure OpenAI | Models deployed in your own Azure tenant |
| Anthropic | Claude models |
| xAI (Grok) | Grok models |
| Google (Gemini) | Gemini models |
| Custom LLM | Any OpenAI-compatible endpoint — Ollama, vLLM, LM Studio, LocalAI and similar |

The provider is set per chat role, so different groups of users can run against different
models without a second installation.

### What it does

- **Answers from live data.** The model calls built-in tools to query tables, look up
  records, follow document relationships and produce deep links back into Business Central.
- **Runs inside your security model.** Every tool call executes as the signed-in user. The
  assistant cannot read what that user cannot read.
- **Isolates tool failures.** Each call runs in its own scope, so one failed lookup does not
  end the conversation.
- **Knows who it is talking to.** Session bootstrap supplies user identity, company context
  and role information before the first question.
- **Personal or shared keys.** Users can hold their own API key, or an administrator
  configures one shared service key behind a permission set.
- **Configurable per role.** Model, endpoint, timeout up to 600 seconds and token limit up
  to 128 000, all set per chat role without code changes.
- **Logs every call.** API calls are written to the Cloud Events request log. Full request
  and response bodies are recorded when debug mode is on, and redacted when it is off.
- **Setup wizard.** Enables outbound requests and walks through provider configuration.

### Requirements

- Microsoft Dynamics 365 Business Central 28.0 or later, Essentials or Premium
- Origo Cloud Events Core, available separately on Microsoft AppSource
- An endpoint for the chosen provider, reachable over HTTPS. A self-hosted model needs a
  reverse proxy with a publicly trusted certificate — Business Central requires HTTPS
- "Allow HttpClient Requests" enabled for the extension, which the setup wizard handles

### Languages

User interface in English and Icelandic.

---

## Notes for whoever pastes this

- The provider table is generated from `CEChatRoleProv.EnumExt.al`. If a provider is added
  or removed, update this file and the count in the heading above it.
- Do not list supported countries here — they are selected on the **Availability** tab, and
  a mismatch between the two is a listing defect.
- Earlier drafts described the app as a self-hosted-only "Cloud Events LLM" with three
  providers. Both are out of date: the app is **Origo Cloud Events Chat** and ships six.
