# User Scenarios — Origo Cloud Events Chat

**Publisher:** Origo
**Version:** 28.0.0.0
**Submission date:** 2026-09-01
**Prerequisite extension:** Origo Cloud Events Core 28.2.2.0 or later (install first)

---

## Before you start

**Environment.** A Business Central sandbox with the CRONUS demonstration company. Install
*Origo Cloud Events Core* first, then *Origo Cloud Events Chat*.

**What you need to run these.** One provider endpoint and one API key. The app supports six
providers — OpenAI, Azure OpenAI, Anthropic, xAI (Grok), Google (Gemini) and Custom LLM for
any OpenAI-compatible endpoint. Credentials for the provider used during validation are
supplied with the submission.

| Component | What it is | Where it comes from |
|---|---|---|
| Provider endpoint | Base URL for the chosen provider | Supplied with the submission |
| API key | Personal or shared service key | Supplied with the submission |
| Service gate | `CE Chat Svc ori` permission set | Assigned in Business Central |
| Object access | `CE Chat Obj ori` permission set | Assigned in Business Central |

Business Central requires HTTPS with a publicly trusted certificate for outbound calls. A
self-hosted model therefore needs a reverse proxy; a commercial provider needs nothing extra.

**Order.** Scenarios 1 to 4 set the app up. The rest state their own setup.

---

## Scenario 1: Install the extension

**Area:** Installation & Activation

### Setup
1. A Business Central sandbox with *Origo Cloud Events Core* installed.

### Steps
1. Search for `Extension Management` and open it.
2. Install *Origo Cloud Events Chat*.
3. Wait for the installation to complete.
4. Search for `MCP Chat Role List` and open a chat role card.
5. Open the **Chat Provider** dropdown.

### Expected results
- Step 3: the extension installs without error, and no standard Business Central function
  is disturbed.
- Step 5: six providers are listed — OpenAI, Azure OpenAI, Custom LLM, Anthropic,
  xAI (Grok) and Google (Gemini).

---

## Scenario 2: Enable outbound requests

**Area:** Installation & Activation

### Setup
1. Complete Scenario 1.

### Steps
1. Open **Cloud Events Setup**.
2. Read the notification about HTTP client requests.
3. Follow it to the extension settings and enable **Allow HttpClient Requests** for
   *Origo Cloud Events Chat*.
4. Return to **Cloud Events Setup**.

### Expected results
- Step 2: a notification states that HTTP client requests are not enabled. It explains what
  to do rather than failing silently.
- Step 4: the notification is gone, and model lookup and chat are available.

---

## Scenario 3: Configure a provider on a chat role

**Area:** Core functionality — configuration

### Setup
1. Complete Scenario 2.
2. The signed-in user has the `CE Chat Obj ori` permission set.

### Steps
1. Search for `MCP Chat Role List` and open it.
2. Choose **New**.
3. Set **Code** to `VALIDATION` and a description.
4. Set **Chat Provider** to the provider supplied with the submission.
5. Set **Base URL** and **Model** to the supplied values.
6. Set **Timeout Seconds** to 300 and **Max Tokens** to 8192.
7. Tick **Default**.
8. Close the card.

### Expected results
- Step 7: the role becomes the default. Only one role can be default at a time — setting it
  clears the flag on any other.
- Step 8: the role is saved and appears in the list with its provider and model.

---

## Scenario 4: Store a personal API key

**Area:** Core functionality — credentials

### Setup
1. Complete Scenario 3.

### Steps
1. Open a page that shows the chat panel, for example **Customer List**.
2. Read the message shown before a key exists.
3. Enter the supplied API key.
4. Choose **Save Key**.

### Expected results
- Step 2: the panel states that an API key is required, and offers where to enter it.
- Step 4: a confirmation appears and the chat input becomes active.
- The key is stored per user in isolated storage. It is not displayed again, and no other
  user or administrator can read it back.

---

## Scenario 5: Ask a question

**Area:** Core functionality — chat

### Setup
1. Complete Scenario 4.

### Steps
1. Open a page with the chat panel.
2. Type `Who am I?` and send.

### Expected results
- A progress indicator appears while the model is working.
- The answer names the signed-in user, the company and the role, within the configured
  timeout.

---

## Scenario 6: Ask a question that needs live data

**Area:** Core functionality — tool execution

### Setup
1. Complete Scenario 4. At least one customer exists — CRONUS demo data is enough.

### Steps
1. Open the chat panel.
2. Type `How many customers do I have?` and send.
3. If the tool trace is visible, read it.

### Expected results
- The model calls a tool against the Customer table rather than guessing.
- The answer contains a count that matches the Customer list.
- The trace shows the tool call and a success status.

---

## Scenario 7: The assistant cannot exceed the user's permissions

**Area:** Permission verification

### Setup
1. Complete Scenario 4.
2. A second user without SUPER, holding `CE Chat Obj ori` and the Cloud Events Core
   permission sets, and with no access to a chosen table — G/L Entry, for example.

### Steps
1. Sign in as the second user.
2. Open a page with the chat panel and ask a question about data that user can see, such as
   `List three customers`.
3. Ask a question about the restricted table, such as `Show me the latest G/L entries`.

### Expected results
- Step 2: the question is answered normally.
- Step 3: the assistant does not return the restricted data. It reports that it could not
  read it. Tool calls execute as the signed-in user, so the model cannot see past that
  user's permissions.
- No unhandled error, and the conversation continues.

---

## Scenario 8: The service gate

**Area:** Permission verification

### Setup
1. Complete Scenario 3.
2. An administrator has saved a shared service API key.
3. A test user without a personal key.

### Steps
1. Assign `CE Chat Svc ori` to the test user.
2. Sign in as that user, open the chat panel, and send `Hello`.
3. Sign out. Remove `CE Chat Svc ori` from that user.
4. Sign in again and send another message.

### Expected results
- Step 2: chat works using the shared service key, with no prompt for a personal key.
- Step 4: the shared key is no longer available to that user. The app says so, and offers
  the personal key route instead of failing silently.

---

## Scenario 9: Server-side model call

**Area:** Core functionality — message type

### Setup
1. Complete Scenario 3, with an API key available.
2. The signed-in user has `CE Chat Svc ori`.

### Steps
1. Submit a Cloud Event with type `LLM.Model.Call` and payload
   `{"model": "<supplied model>", "prompt": "Reply with exactly: connection ok"}`.
2. Process the task and read the response.

### Expected results
- The response reports success and contains the text `connection ok`.
- The content type is `application/json`.
- A request log entry is written for the call.

---

## Scenario 10: A bad endpoint or key is reported clearly

**Area:** Error handling

### Setup
1. Complete Scenario 3.

### Steps
1. Open the chat role from Scenario 3 and change **Base URL** to a host that does not exist,
   for example `https://no-such-endpoint.origo.is`.
2. Open the chat panel and send a message.
3. Read what is shown.
4. Restore the correct Base URL, then replace the API key with an invalid value.
5. Send another message and read what is shown.
6. Restore the correct key.

### Expected results
- Step 3: the failure is reported in the panel with a reason a user can act on. No stack
  trace, and the page does not hang past the configured timeout.
- Step 5: the authentication failure is reported as such, distinct from the unreachable
  endpoint above.
- Step 6: after restoring the key, chat works again without reinstalling or restarting.

---

## Scenario 11: Request logging and redaction

**Area:** Data integrity

### Setup
1. Complete Scenario 4.

### Steps
1. Open **Cloud Events Setup** and enable **Request Debug Mode**.
2. Send a chat message.
3. Open the request log and filter to this app's entries.
4. Open the newest entry and read the request and response bodies.
5. Turn **Request Debug Mode** off and send another message.
6. Open the newest entry again.

### Expected results
- Step 4: the entry records the operation and an HTTP 200, with full bodies while debug mode
  is on.
- Step 6: a new entry is written, but the bodies are redacted. The API key never appears in
  the log in either mode.

---

## Scenario 12: Permissions for a non-SUPER user

**Area:** Permission verification

### Setup
1. Complete Scenario 3.
2. A third user without SUPER and without any of this app's permission sets.

### Steps
1. Sign in as that user and open a page that would show the chat panel.
2. Sign out. As an administrator, assign `CE Chat Obj ori` to that user.
3. Sign in again and open the same page.
4. Send a message.

### Expected results
- Step 1: the app's functionality is not available, and the user sees a permission message
  rather than an unhandled error.
- Steps 3 and 4: with `CE Chat Obj ori` the user reaches the chat panel and, with a key
  available, can chat.

### Notes for the reviewer
`CE Chat Obj ori` grants the app's objects. `CE Chat Svc ori` is separate and controls the
shared service key only. Customers who use Cloud Events Core's own roles get this app's
objects through the `CE Chat Full ori` and `CE Chat Read ori` extensions without assigning
anything new.

---

## Scenario 13: Uninstall and reinstall

**Area:** Uninstallation

### Setup
1. Complete Scenarios 3 and 4, so the app has configuration and at least one logged call.

### Steps
1. Open **Extension Management** and select *Origo Cloud Events Chat*.
2. Choose **Uninstall**, leaving **Delete extension data** unchecked.
3. Open **Cloud Events Setup** and confirm it still works.
4. Open **Customer List** and confirm standard pages behave normally.
5. Reinstall the extension.
6. Open a chat role and confirm the provider configuration is intact.

### Expected results
- Step 2: the extension uninstalls without error.
- Steps 3 and 4: Cloud Events Core and standard Business Central continue to work. The chat
  panel is simply absent.
- Step 5: the reinstall succeeds — no leftover data blocks it.
- Step 6: the chat role and its provider are still configured.

### Notes
Repeating steps 1 and 2 with **Delete extension data** checked must also succeed and leave
Business Central working.

---

## Coverage

| Required category | Scenarios |
|---|---|
| Installation & activation | 1, 2 |
| Core functionality | 3, 4, 5, 6, 9 |
| Error handling | 10 |
| Data integrity | 11, 13 |
| Permission verification | 7, 8, 12 |
| Uninstallation | 13 |
