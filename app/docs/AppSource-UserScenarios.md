# User Scenarios — Cloud Events LLM

**Publisher:** Origo
**Version:** 28.0.0.0
**Submission Date:** 2026-08-25
**Test Environment:** Requires a self-hosted OpenAI-compatible LLM endpoint (e.g., Ollama) accessible via HTTPS through a reverse proxy.

---

## Test Credentials

| Component | Credential Type | How to Obtain |
|-----------|----------------|---------------|
| LLM API | API key (x-api-key header) | Defined in reverse proxy config |
| BC User | Standard BC user | Part of test environment |
| Service Gate | `CE LLM Svc` permission set | Assign via BC User Setup |

---

## Scenario 1: Install Extension

**Area:** Installation

### Setup
1. Open a Business Central environment (online sandbox or production).
2. Ensure "Origo Cloud Events Core" is already installed.

### Steps
1. Navigate to Extension Management.
2. Search for "Cloud Events LLM".
3. Install the extension.
4. Wait for installation to complete.

### Expected Results
- Extension installs without errors.
- No data loss or service interruption.
- Cloud Events Setup page shows an "LLM Chat" group (visible only with the service gate permission set).

---

## Scenario 2: Enable HTTP Client Requests

**Area:** Extension Settings

### Setup
1. Extension is installed.
2. User is an administrator.

### Steps
1. Open Cloud Events Setup.
2. A notification appears: "HTTP client requests are not enabled..."
3. Click "Open Extension Settings".
4. Enable "Allow HttpClient Requests" for the Cloud Events LLM extension.
5. Return to Cloud Events Setup.

### Expected Results
- The notification no longer appears after enabling.
- The LLM model lookup and chat features are now functional.

---

## Scenario 3: Configure LLM Endpoint

**Area:** Cloud Events Setup

### Setup
1. Extension is installed.
2. HTTP client requests are enabled.
3. Current user has the `CE LLM Svc` permission set assigned.

### Steps
1. Open Cloud Events Setup.
2. The "LLM Chat" group shows fields: LLM Base URL, Service API Key, LLM Default Model, API Timeout, Max Output Tokens.
3. Verify the Base URL is set to `https://llm.kappi.is` (or your endpoint).
4. Enter the Service API Key.
5. Click the lookup on "LLM Default Model".
6. Select a model from the list (e.g., qwen3:8b).
7. Set API Timeout to 300 seconds.
8. Set Max Output Tokens to 4096.
9. Save the record.

### Expected Results
- The model lookup calls `/v1/models` on the configured endpoint and shows available models.
- The selected model is saved and used as the default for all chat sessions that don't override it via a Chat Role.
- The timeout and token fields show their configured values.

---

## Scenario 4: Configure Personal API Key

**Area:** User Setup

### Setup
1. Extension is installed.
2. HTTP client requests are enabled.

### Steps
1. Open any page with the MCP Chat FactBox (e.g., Customer List).
2. The chat panel shows "LLM API Key Required" with a link to the LLM Console.
3. Enter a valid API key in the input field.
4. Click "Save Key".

### Expected Results
- Message shows "API key saved. You can now chat."
- The chat input field becomes active.
- The API key is stored per-user and is not visible to other users or administrators.

---

## Scenario 5: Send a Chat Message

**Area:** MCP Chat

### Setup
1. A valid API key is configured (Scenario 3 or 4).

### Steps
1. Open a page with the MCP Chat FactBox.
2. Type "Who am I?" in the chat input.
3. Press Send.

### Expected Results
- The assistant responds with the current user's name, company, and role information.
- A "Thinking..." indicator is shown while waiting for the response.
- The response appears in the chat panel within the configured timeout period.

---

## Scenario 6: Query Live BC Data

**Area:** MCP Chat — Tool Use

### Setup
1. A valid API key is configured.
2. At least one customer exists in the database.

### Steps
1. Open the MCP Chat FactBox.
2. Type "How many customers do I have?" and press Send.

### Expected Results
- The model calls the appropriate tool to query the Customer table.
- The response shows the customer count.
- The tool trace (if visible) shows the tool call with status "success".

---

## Scenario 7: Service Gate Restricts Access

**Area:** Permission Gate

### Setup
1. Extension is installed.
2. Current user does NOT have the `CE LLM Svc` permission set.

### Steps
1. Open Cloud Events Setup.
2. Look for the "LLM Chat" group.

### Expected Results
- The "LLM Chat" group is not visible.
- The user cannot see or modify the service API key, default model, timeout, or max tokens.

---

## Scenario 8: Shared Service Key for Gated Users

**Area:** Service Gate + Chat

### Setup
1. An administrator has set the Service API Key in Cloud Events Setup.
2. A test user has the `CE LLM Svc` permission set but no personal API key.

### Steps
1. Log in as the test user.
2. Open a page with the MCP Chat FactBox.
3. Type "Hello" and press Send.

### Expected Results
- The chat works using the shared service key — no personal key prompt is shown.
- The response comes from the configured LLM model as expected.

---

## Scenario 9: Server-Side LLM.Model.Call

**Area:** Message Type

### Setup
1. The Service API Key is configured in Cloud Events Setup.
2. Current user has the `CE LLM Svc` permission set.

### Steps
1. Submit a Cloud Event message with Type = `LLM.Model.Call`.
2. Set the JSON payload to: `{"model": "qwen3:8b", "prompt": "Reply with exactly: connection ok"}`.
3. Process the task.
4. Retrieve the response.

### Expected Results
- Response contains `{"status": "Success", "model": "qwen3:8b", "text": "connection ok"}`.
- Response Content-Type is `application/json`.
- A request log entry is created with Operation = "chat/completions".

---

## Scenario 10: Request Logging

**Area:** Request Log

### Setup
1. The Service API Key is configured.
2. "Request Debug Mode" is enabled in Cloud Events Setup.

### Steps
1. Send a chat message (any scenario above).
2. Open the Request Log List.
3. Filter by Service Name = "LLM".

### Expected Results
- A log entry exists for the API call.
- Operation shows "chat/completions" or "models".
- HTTP Status shows 200.
- With debug mode on, the Request Body and Response Body contain the full JSON payloads.
- With debug mode off, bodies show "***REDACTED***".

---

## Scenario 11: Uninstall Extension

**Area:** Uninstallation

### Steps
1. Navigate to Extension Management.
2. Find "Cloud Events LLM".
3. Uninstall the extension.

### Expected Results
- Extension uninstalls without errors.
- No data loss in other extensions or base application.
- Cloud Events Core continues to function normally.
