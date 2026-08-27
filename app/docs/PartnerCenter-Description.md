# Description (Rich Text)

### Self-Hosted AI Chat for Business Central with Live Data Access

**Cloud Events LLM** adds any OpenAI-compatible language model as an AI chat provider for Business Central — enabling natural language conversations that can read, search, and act on your live BC data through the Cloud Events tool server. Use your own infrastructure: Ollama, vLLM, LM Studio, or any endpoint that speaks the OpenAI Chat Completions API.

Built on the **Origo Cloud Events Core** framework, this extension registers three LLM Chat Providers (OpenAI, Azure OpenAI, and Custom LLM) on the Core's MCP Chat Role system. Administrators create Chat Roles, assign a provider, and configure the endpoint. Users chat with the model directly inside Business Central pages. The model uses 20+ built-in tools to query tables, look up records, navigate documents, manage memory, and invoke any Cloud Events message type — all within the user's security context.

### Who is this for?

**Organizations with data residency requirements** who need AI-powered BC assistance but cannot send data to external cloud AI services. Run the model on your own hardware — your data never leaves your network.

**Teams already running Ollama, vLLM, or similar** who want to connect their existing LLM infrastructure directly to Business Central without writing custom integrations.

**Business users** who want to ask questions about their BC data in plain language — customer balances, open orders, inventory levels, posting status — without learning filters, pages, or report parameters.

**Administrators** who want to control model selection, API access, and cost by running inference on their own GPU hardware or cloud VMs.

### Key Capabilities

- **Three Chat Providers** — OpenAI (Bearer auth), Azure OpenAI (api-key auth), and Custom LLM (x-api-key auth for self-hosted endpoints like Ollama, vLLM, LM Studio).
- **Any OpenAI-compatible endpoint** — Works with Ollama, vLLM, LM Studio, LocalAI, text-generation-webui, OpenAI, Grok, Groq, Mistral, DeepSeek, Together AI, and Azure OpenAI.
- **Natural language queries** — Ask about customers, vendors, items, G/L entries, and any BC table. The model translates your question into the right tool calls.
- **20+ built-in tools** — Record read/write, entity search, document navigation, memory, blob storage, deep links to BC pages, and more.
- **Tool execution with isolation** — Each tool call runs in its own Codeunit.Run scope. Failed calls don't break the conversation.
- **Session bootstrap** — Automatic identity detection, user/company memory loading, and API primer for context-aware responses.
- **Per-user or shared API key** — Users can bring their own API key, or administrators can configure a shared service key gated by a permission set.
- **Configurable model** — Model set per MCP Chat Role. Per-role model override on the Chat Role card.
- **Configurable limits** — Timeout (up to 600 seconds) and max tokens (up to 128,000) adjustable per Chat Role without code changes.
- **Permission gate** — Service key access requires the `CE LLM Svc` permission set. Server-side message types (`LLM.Model.Call`, `LLM.Model.List`, `Provider.List`) are gated by whether any Chat Role with a provider is configured.
- **Request logging** — All API calls are logged to the shared Cloud Events Request Log. Full request/response bodies stored when Request Debug Mode is enabled.
- **Reverse proxy friendly** — Designed to work behind Caddy, nginx, Traefik, or any reverse proxy. Authentication via `x-api-key` header.

### How It Works

Users open the MCP Chat panel (FactBox or Focus page) on any BC page. The chat control add-in connects to the LLM through the in-process tool server — no external proxy or Azure Function needed. The model receives a system prompt with the user's identity, company context, memory, role skill, and an API primer. When the user asks a question, the model calls tools to fetch live data, then responds in natural language. The Chat Provider on the user's assigned MCP Chat Role determines which LLM endpoint and authentication scheme is used.

### Architecture

```
Business Central  →  HTTPS  →  Reverse Proxy (Caddy/nginx)  →  Ollama/vLLM
                                (TLS termination + auth)         (local network)
```

BC's `HttpClient` requires HTTPS with a publicly trusted certificate. A reverse proxy handles TLS termination and optional API key validation, then forwards requests to your LLM server over HTTP on your local network.

### Security Model

- Each user's API key is stored in per-user IsolatedStorage (encrypted, never exposed).
- The shared service API key is stored in company-scoped IsolatedStorage, accessible only to users with the `CE LLM Svc` permission set.
- All tool calls execute under the current user's BC permissions. The model cannot access data the user cannot see.
- Server-side message types require the service gate permission.
- API key authentication at the reverse proxy layer prevents unauthorized access to your LLM.

### Requirements and Prerequisites

- Microsoft Dynamics 365 Business Central 28.0 or later (Essentials or Premium)
- Origo Cloud Events Core extension (available separately on AppSource)
- An OpenAI-compatible LLM endpoint accessible via HTTPS (e.g., Ollama behind Caddy)
- A publicly trusted TLS certificate on the reverse proxy (Let's Encrypt recommended)
- "Allow HttpClient Requests" must be enabled for the extension

### Recommended Models

| Model | Parameters | Context | Notes |
|-------|-----------|---------|-------|
| qwen3:8b | 8B | 32K | Excellent tool calling, fast on Apple Silicon |
| qwen2.5:14b | 14B | 24K | Strong reasoning, needs 16GB+ VRAM |
| llama3.1:8b | 8B | 128K | Good general use, less reliable tool calling |
| mistral-small3.1 | 24B | 128K | Powerful but needs 32GB+ VRAM |
