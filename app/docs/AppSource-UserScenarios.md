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
- The three Chat Provider values (OpenAI, Azure OpenAI, Custom LLM) appear in the MCP Chat Role Card's Chat Provider dropdown.

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

## Scenario 3: Configure LLM Provider via MCP Chat Role

**Area:** MCP Chat Role Setup

### Setup
1. Extension is installed.
2. HTTP client requests are enabled.
3. Current user has the `CE LLM Svc` permission set assigned.

### Steps
1. Search for **MCP Chat Role List** and open it.
2. Click **New** to create a role.
3. Set Code to `OLLAMA` and Description to `Ollama (Self-Hosted)`.
4. Set **Chat Provider** to `Custom LLM`.
5. Set **Base URL** to `https://llm.kappi.is` (or your endpoint).
6. Set **Model** to `qwen3:8b`.
7. Set **Timeout Seconds** to 300.
8. Set **Max Tokens** to 8192.
9. Check the **Default** checkbox.
10. Save the record.

### Expected Results
- The role is created with all configured fields.
- The role appears in the MCP Chat Role List.
- The Default flag is set; only one role can be default at a time.
- The chat panel uses this role's provider when no explicit role override exists.

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
2. An MCP Chat Role with a Chat Provider is set as Default.

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
2. An MCP Chat Role with a Chat Provider is set as Default.
3. At least one customer exists in the database.

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
3. No MCP Chat Role exists with a Chat Provider configured.

### Steps
1. Try to submit a Cloud Event with Type = `LLM.Model.Call`.

### Expected Results
- The message type's `IsEnabled` returns false when no role with a Chat Provider is configured.
- The service gate prevents execution and responds with an error message.

---

## Scenario 8: Shared Service Key for Gated Users

**Area:** Service Gate + Chat

### Setup
1. An administrator has configured an MCP Chat Role with a Chat Provider and saved a Service API Key.
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
1. An MCP Chat Role with a Chat Provider is configured and has an API key available.
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
1. An API key is configured (via MCP Chat Role service key or per-user key).
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
