# Azure AI Foundry Setup

This guide covers provisioning an Azure OpenAI resource for use as an LLM provider in Business Central.

---

## Overview

Azure AI Foundry provides pay-per-token model deployments with no cost at rest. You only pay when the API is called. This makes it ideal for testing and low-volume production use.

---

## Prerequisites

- Azure subscription with `Microsoft.CognitiveServices` provider registered
- Azure CLI (`az`) authenticated
- Sufficient quota for the desired model and SKU

---

## Provisioning

### 1. Create Resource Group

```powershell
az group create --name <resource-group> --location swedencentral
```

### 2. Create Azure OpenAI Account

```powershell
az cognitiveservices account create `
  --name <account-name> `
  --resource-group <resource-group> `
  --location swedencentral `
  --kind OpenAI `
  --sku S0
```

The S0 SKU has no base charge — billing is purely per-token.

### 3. Deploy a Model

```powershell
az cognitiveservices account deployment create `
  --name <account-name> `
  --resource-group <resource-group> `
  --deployment-name <deployment-name> `
  --model-name gpt-4o `
  --model-version "2024-11-20" `
  --model-format OpenAI `
  --sku-capacity 150 `
  --sku-name "Standard"
```

**SKU options:**

| SKU | Billing | Use case |
|-----|---------|----------|
| Standard | Pay-per-token, region-local | General use |
| DataZoneStandard | Pay-per-token, data zone routing | Higher quota limits |
| GlobalStandard | Pay-per-token, global routing | Highest availability |

### 4. Get API Key

```powershell
az cognitiveservices account keys list `
  --name <account-name> `
  --resource-group <resource-group> `
  --query key1 -o tsv
```

---

## MCP Chat Role Configuration in Business Central

Create an MCP Chat Role record with these settings:

| Field | Value |
|-------|-------|
| Code | `FOUNDRY` (or any identifier) |
| Description | Azure Foundry |
| Chat Provider | Azure OpenAI |
| Base URL | `https://<account-name>.openai.azure.com` |
| Model | The deployment name (e.g., `gpt-4o`) |
| Timeout Seconds | 120 |
| Max Tokens | 16384 |

**Important:** Azure OpenAI uses the `api-key` header for authentication (handled automatically by the Azure OpenAI Chat Provider). The extension appends `/v1/chat/completions` to the Base URL for chat requests.

---

## Quota and Rate Limits

Azure OpenAI enforces **Tokens Per Minute (TPM)** quotas per model per region per subscription.

Check your quota:

```powershell
az cognitiveservices usage list --location swedencentral --output json |
  ConvertFrom-Json |
  Where-Object { $_.name.value -match "Standard\.gpt" } |
  ForEach-Object { "$($_.name.value): used=$($_.currentValue) limit=$($_.limit)" }
```

### Capacity Planning for Tool-Calling Agents

The agentic tool loop sends multiple requests per user message (one per tool-call iteration). Each iteration carries the full conversation history plus all tool definitions, so token consumption grows with each round-trip.

**Rule of thumb:** An agent with 10–20 tools running 5–7 iterations can consume 100K+ tokens per user message. Set deployment capacity to at least 150K TPM for comfortable headroom.

If you hit 429 (rate limit) errors:
1. Increase `--sku-capacity` on the deployment
2. Consider DataZoneStandard SKU for higher limits
3. Use a smaller model (e.g., `gpt-5.4-mini`) which typically has higher quota allocations

---

## Model Selection

| Model | Strength | Quota (typical) | Notes |
|-------|----------|-----------------|-------|
| **gpt-5.4-mini** | Strong reasoning, fast | 1000K TPM (DataZoneStandard) | **Recommended for BC tool-calling** |
| gpt-4o | Excellent reasoning + tool calling | 150K TPM (Standard) | Best quality, lower quota |
| gpt-4.1-mini | Good reasoning | Varies | Legacy, still functional |

### Recommended: gpt-5.4-mini (DataZoneStandard)

For Business Central agentic workloads with tool calling, **gpt-5.4-mini** with **DataZoneStandard** SKU is the recommended deployment:

- 1,000K TPM quota — handles multi-iteration tool loops without rate limiting
- Strong tool-calling and reasoning capabilities (well above Haiku-class)
- Pay-per-token, no cost at rest
- Fast inference (~1-2s per round-trip)

```powershell
az cognitiveservices account deployment create `
  --name <account-name> `
  --resource-group <resource-group> `
  --deployment-name gpt-5-4-mini `
  --model-name gpt-5.4-mini `
  --model-version "2026-03-17" `
  --model-format OpenAI `
  --sku-capacity 1000 `
  --sku-name "DataZoneStandard"
```

gpt-4o (Standard) is available as a higher-quality alternative but is limited to 150K TPM per subscription in most regions, which can cause 429 errors during multi-tool conversations.

For the full list of models tested with this extension, see [Provider-Setup.md](Provider-Setup.md).

---

## API Parameter Notes

Newer models (gpt-4o 2024-08+ and all gpt-5.x) require `max_completion_tokens` instead of `max_tokens`. This extension sends `max_completion_tokens` for compatibility with current and future models.

---

## Cost

| Component | Cost at Rest | Cost When Used |
|-----------|-------------|----------------|
| Resource Group | Free | — |
| Azure OpenAI Account (S0) | Free | — |
| Standard deployment | Free | Per-token pricing |

Pricing varies by model. Check [Azure OpenAI pricing](https://azure.microsoft.com/pricing/details/cognitive-services/openai-service/) for current rates.

---

## Cleanup

To remove all resources and stop any potential charges:

```powershell
az group delete --name <resource-group> --yes
```
