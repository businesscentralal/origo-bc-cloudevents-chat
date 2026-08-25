# Provider Setup Guide

This guide explains how to configure LLM providers in Business Central and where to obtain API keys for each supported service.

---

## Quick Start

1. Open **Cloud Events Setup** → click **LLM Providers**
2. Create a new provider record
3. Fill in: Code, Name, Base URL, Auth Type, Default Model
4. Enter the Service API Key (or let users enter their own per-user key in the chat UI)
5. Click **Test Connection** to verify
6. Set the provider as the **Default LLM Provider** on Cloud Events Setup

---

## Provider Configuration Reference

### Self-Hosted (Ollama via Reverse Proxy)

| Field | Value |
| ----- | ----- |
| Code | `OLLAMA` |
| Name | Ollama (Self-Hosted) |
| Base URL | `https://llm.yourdomain.com` |
| Auth Type | x-api-key (Reverse Proxy) |
| Default Model | `qwen3:8b` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** You define this yourself in your reverse proxy configuration (Caddy, nginx, etc.). See [ReverseProxy-Setup.md](ReverseProxy-Setup.md) for details.

Generate a key: `openssl rand -hex 32`

---

### OpenAI

| Field | Value |
| ----- | ----- |
| Code | `OPENAI` |
| Name | OpenAI |
| Base URL | `https://api.openai.com` |
| Auth Type | Bearer (OpenAI-compatible) |
| Default Model | `gpt-4o` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [platform.openai.com/api-keys](https://platform.openai.com/api-keys)

1. Sign in to your OpenAI account
2. Navigate to API Keys
3. Click "Create new secret key"
4. Copy the key (starts with `sk-...`)

**Pricing:** Pay-per-token. See [openai.com/pricing](https://openai.com/pricing)

---

### Grok (xAI)

| Field | Value |
| ----- | ----- |
| Code | `GROK` |
| Name | Grok (xAI) |
| Base URL | `https://api.x.ai` |
| Auth Type | Bearer (OpenAI-compatible) |
| Default Model | `grok-2` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [console.x.ai](https://console.x.ai/)

1. Sign in with your X (Twitter) account
2. Navigate to API Keys
3. Create a new key
4. Copy the key (starts with `xai-...`)

**Pricing:** Pay-per-token. See [x.ai/api](https://x.ai/api)

---

### Groq

| Field | Value |
| ----- | ----- |
| Code | `GROQ` |
| Name | Groq |
| Base URL | `https://api.groq.com/openai` |
| Auth Type | Bearer (OpenAI-compatible) |
| Default Model | `llama-3.1-70b-versatile` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [console.groq.com/keys](https://console.groq.com/keys)

1. Sign up or sign in
2. Navigate to API Keys
3. Create a new key
4. Copy the key (starts with `gsk_...`)

**Pricing:** Free tier available with rate limits. See [groq.com/pricing](https://groq.com/pricing)

---

### Together AI

| Field | Value |
| ----- | ----- |
| Code | `TOGETHER` |
| Name | Together AI |
| Base URL | `https://api.together.xyz` |
| Auth Type | Bearer (OpenAI-compatible) |
| Default Model | `meta-llama/Llama-3.1-70B-Instruct-Turbo` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [api.together.ai/settings/api-keys](https://api.together.ai/settings/api-keys)

1. Sign up or sign in
2. Navigate to Settings → API Keys
3. Create a new key
4. Copy the key

**Pricing:** Pay-per-token. See [together.ai/pricing](https://together.ai/pricing)

---

### Mistral AI

| Field | Value |
| ----- | ----- |
| Code | `MISTRAL` |
| Name | Mistral AI |
| Base URL | `https://api.mistral.ai` |
| Auth Type | Bearer (OpenAI-compatible) |
| Default Model | `mistral-large-latest` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [console.mistral.ai/api-keys](https://console.mistral.ai/api-keys)

1. Sign up or sign in
2. Navigate to API Keys
3. Create a new key
4. Copy the key

**Pricing:** Pay-per-token. See [mistral.ai/technology](https://mistral.ai/technology)

---

### DeepSeek

| Field | Value |
| ----- | ----- |
| Code | `DEEPSEEK` |
| Name | DeepSeek |
| Base URL | `https://api.deepseek.com` |
| Auth Type | Bearer (OpenAI-compatible) |
| Default Model | `deepseek-chat` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys)

1. Sign up or sign in
2. Navigate to API Keys
3. Create a new key
4. Copy the key (starts with `sk-...`)

**Pricing:** Pay-per-token. See [platform.deepseek.com/api-docs/pricing](https://platform.deepseek.com/api-docs/pricing)

---

### Azure AI Foundry (Models as a Service)

| Field | Value |
| ----- | ----- |
| Code | `AZURE` |
| Name | Azure AI Foundry |
| Base URL | `https://{deployment}.{region}.models.ai.azure.com` |
| Auth Type | api-key (Azure) |
| Default Model | `gpt-4o` |
| Chat Path | `/v1/chat/completions` |
| Models Path | `/v1/models` |

**API Key:** Obtain from [Azure AI Foundry portal](https://ai.azure.com/)

1. Sign in to Azure AI Foundry
2. Open your project
3. Navigate to Deployments
4. Select your model deployment
5. Copy the Key from the deployment details

**Note:** The Base URL includes your deployment name and region. Each deployment has its own endpoint. For Azure OpenAI Service (non-MaaS), the paths differ — use a reverse proxy to normalize the URL structure if needed.

**Pricing:** Based on your Azure subscription. See [azure.microsoft.com/pricing/details/cognitive-services/openai-service](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service)

---

## Authentication Model

Each provider supports two API key layers:

### Service Key (Shared, Gated)

- Set on the **Provider Card** under Authentication
- Stored in `IsolatedStorage` with Module scope (encrypted, shared across all users)
- Only visible to users with the **CE LLM Svc** permission set
- All gated users share this key — one bill, centralized management

### Per-User Key

- Each user enters their own key via the chat UI (API Key prompt)
- Stored in `IsolatedStorage` with User scope (private, per-user)
- Takes priority over the service key
- Useful when users have their own accounts or for cost attribution

### Resolution Order

1. Per-user key exists → use it
2. User has `CE LLM Svc` permission + service key exists → use service key
3. Neither → chat shows "API Key Required" prompt

---

## Recommended Models for Tool Calling

Not all models handle tool calling (function calling) well. These are tested and recommended:

| Provider | Model | Tool Calling Quality | Notes |
| -------- | ----- | -------------------- | ----- |
| Ollama | `qwen3:8b` | Excellent | Best balance for 16GB hardware |
| Ollama | `qwen2.5:14b` | Excellent | Needs 16GB+ VRAM |
| OpenAI | `gpt-4o` | Excellent | Best overall |
| OpenAI | `gpt-4o-mini` | Good | Lower cost |
| Grok | `grok-2` | Excellent | Fast |
| Groq | `llama-3.1-70b-versatile` | Good | Very fast inference |
| Mistral | `mistral-large-latest` | Excellent | Strong reasoning |
| DeepSeek | `deepseek-chat` | Good | Cost-effective |
| Azure | `gpt-4o` | Excellent | Enterprise compliance |

---

## Troubleshooting

| Issue | Solution |
| ----- | -------- |
| "Provider not found" error | Verify the provider Code matches exactly (case-sensitive) |
| "No API key available" | Set a service key on the provider card, or enter a per-user key |
| Test Connection fails with 401 | Wrong API key — verify it matches the provider's console |
| Test Connection fails with timeout | Increase Timeout Seconds on the provider card |
| Models list is empty | Some providers don't support `/v1/models` — enter models manually on Chat Roles |
| Provider not showing in lookup | Ensure the provider's Enabled checkbox is checked |
