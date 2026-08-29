# Provider Setup Guide

This guide explains how to configure LLM providers in Business Central via **MCP Chat Roles** and where to obtain API keys for each supported service.

---

## Quick Start

1. Open **MCP Chat Role List** (search in BC)
2. Create a new role record with a Code and Description
3. Set **Chat Provider** to OpenAI, Azure OpenAI, or Custom LLM
4. Fill in: Base URL, Model, Timeout Seconds, Max Tokens (defaults are applied when you select a provider)
5. Enter the API Key via the chat UI, or save a shared Service Key on the role card
6. Optionally mark the role as **Default**

---

## Chat Provider Types

The extension registers three Chat Provider options on the Core MCP Chat Role enum:

| Chat Provider | Auth Header | Default Base URL | Use For |
| ------------- | ----------- | ---------------- | ------- |
| **OpenAI** | `Authorization: Bearer` | `https://api.openai.com` | OpenAI, Groq, Together, Mistral, DeepSeek, Google Gemini (OpenAI mode), and other Bearer-auth endpoints |
| **Azure OpenAI** | `api-key` | *(must configure)* | Azure OpenAI Service deployments |
| **Custom LLM** | `x-api-key` | *(must configure)* | Ollama, vLLM, LM Studio, or any endpoint behind a reverse proxy with x-api-key auth |
| **Anthropic** | `x-api-key` + `anthropic-version` | `https://api.anthropic.com` | Anthropic Claude models |
| **xAI (Grok)** | `Authorization: Bearer` | `https://api.x.ai` | xAI Grok models with full file/document processing support |
| **Google (Gemini)** | API key (URL param) | `https://generativelanguage.googleapis.com/v1beta` | Google Gemini models with native PDF/image processing |

---

## Provider Configuration Reference

### Self-Hosted (Ollama via Reverse Proxy)

| Field | Value |
| ----- | ----- |
| Code | `OLLAMA` |
| Description | Ollama (Self-Hosted) |
| Chat Provider | Custom LLM |
| Base URL | `https://llm.yourdomain.com` |
| Model | `qwen3:8b` |
| Timeout Seconds | 300 |
| Max Tokens | 8192 |

**API Key:** You define this yourself in your reverse proxy configuration (Caddy, nginx, etc.). See [ReverseProxy-Setup.md](ReverseProxy-Setup.md) for details.

Generate a key: `openssl rand -hex 32`

---

### OpenAI

| Field | Value |
| ----- | ----- |
| Code | `OPENAI` |
| Description | OpenAI |
| Chat Provider | OpenAI |
| Base URL | *(leave empty — defaults to `https://api.openai.com`)* |
| Model | `gpt-4.1` |

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
| Description | Grok (xAI) |
| Chat Provider | xAI (Grok) |
| Base URL | *(leave empty — defaults to `https://api.x.ai`)* |
| Model | `grok-3` |

**API Key:** Obtain from [console.x.ai](https://console.x.ai/)

1. Sign in with your X (Twitter) account
2. Navigate to API Keys
3. Create a new key
4. Copy the key (starts with `xai-...`)

**Note:** Use the **xAI (Grok)** provider for full document/PDF processing support. The OpenAI provider also works for text-only chat but does not support file attachments with Grok.

**Pricing:** Pay-per-token. See [x.ai/api](https://x.ai/api)

---

### Groq

| Field | Value |
| ----- | ----- |
| Code | `GROQ` |
| Description | Groq |
| Chat Provider | OpenAI |
| Base URL | `https://api.groq.com/openai` |
| Model | `llama-3.1-70b-versatile` |

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
| Description | Together AI |
| Chat Provider | OpenAI |
| Base URL | `https://api.together.xyz` |
| Model | `meta-llama/Llama-3.1-70B-Instruct-Turbo` |

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
| Description | Mistral AI |
| Chat Provider | OpenAI |
| Base URL | `https://api.mistral.ai` |
| Model | `mistral-large-latest` |

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
| Description | DeepSeek |
| Chat Provider | OpenAI |
| Base URL | `https://api.deepseek.com` |
| Model | `deepseek-chat` |

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
| Description | Azure AI Foundry |
| Chat Provider | Azure OpenAI |
| Base URL | `https://<account-name>.openai.azure.com` |
| Model | *(deployment name, e.g., `gpt-4o`)* |

**API Key:** Obtain from [Azure AI Foundry portal](https://ai.azure.com/)

1. Sign in to Azure AI Foundry
2. Open your project
3. Navigate to Deployments
4. Select your model deployment
5. Copy the Key from the deployment details

**Note:** Azure OpenAI uses a different URL structure. The extension appends `/v1/chat/completions` to the Base URL. For standard Azure OpenAI endpoints, this works with Azure's OpenAI-compatible paths. For custom deployment paths, use a reverse proxy to normalize the URL structure.

**Pricing:** Based on your Azure subscription. See [azure.microsoft.com/pricing/details/cognitive-services/openai-service](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service)

---

### Google Gemini

| Field | Value |
| ----- | ----- |
| Code | `GEMINI` |
| Description | Google Gemini |
| Chat Provider | Google (Gemini) |
| Base URL | *(leave empty — defaults to `https://generativelanguage.googleapis.com/v1beta`)* |
| Model | `gemini-2.5-flash` |

**API Key:** Obtain from [aistudio.google.com/apikey](https://aistudio.google.com/apikey)

1. Sign in with your Google account
2. Click "Create API key"
3. Select or create a Google Cloud project
4. Copy the key

**Note:** Use the **Google (Gemini)** provider for full document/PDF and image processing support. Text-only chat also works via the OpenAI provider with Google's OpenAI-compatible endpoint, but file attachments require the native Gemini API.

**Pricing:** Free tier available. See [ai.google.dev/pricing](https://ai.google.dev/pricing)

---

## Authentication Model

Each Chat Provider supports two API key layers:

### Service Key (Shared, Gated)

- Saved via the provider implementation's Service Key action
- Stored in `IsolatedStorage` with Company scope (encrypted, shared across all users)
- Only accessible to users with the **CE LLM Svc** permission set
- All gated users share this key — one bill, centralized management

### Per-User Key

- Each user enters their own key via the chat UI (API Key prompt)
- Stored in `IsolatedStorage` with Company scope, keyed per user (private, per-user)
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
| OpenAI | `gpt-4.1` | Excellent | Best overall |
| OpenAI | `gpt-4o-mini` | Good | Lower cost |
| Grok | `grok-3` | Excellent | Fast, supports PDF via Responses API |
| Groq | `llama-3.1-70b-versatile` | Good | Very fast inference |
| Mistral | `mistral-large-latest` | Excellent | Strong reasoning |
| DeepSeek | `deepseek-chat` | Good | Cost-effective |
| Azure | `gpt-4o` | Excellent | Enterprise compliance |
| Anthropic | `claude-sonnet-4-6` | Excellent | Best document processing |
| Google | `gemini-2.5-flash` | Excellent | Fast, generous free tier |

---

## Troubleshooting

| Issue | Solution |
| ----- | -------- |
| "Provider not found" error | Verify the role Code matches exactly (case-sensitive) |
| "API key not configured" | Enter a per-user key in the chat UI, or save a service key |
| Chat not working with 401 | Wrong API key — verify it matches the provider's console |
| Timeout errors | Increase Timeout Seconds on the MCP Chat Role card |
| Models list is empty | Some providers don't support `/v1/models` (e.g., Azure OpenAI) |
| "LLM is not configured" | Create an MCP Chat Role and set its Chat Provider |
