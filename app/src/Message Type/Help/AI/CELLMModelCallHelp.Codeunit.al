namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Provides runtime help documentation for the LLM.Model.Call message type.
/// </summary>
codeunit 10035492 "CE LLM Model Call Help ori"
{
    Access = Internal;

    /// <summary>
    /// Returns help text for the LLM.Model.Call message type in Markdown format.
    /// </summary>
    internal procedure GetHelpText() HelpText: Text
    var
        HelpBuilder: TextBuilder;
    begin
        HelpBuilder.AppendLine('# LLM.Model.Call');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Overview');
        HelpBuilder.AppendLine('Sends a prompt to a named LLM model via the OpenAI-compatible Chat Completions API and returns the assistant text. Runs server-side directly against the configured LLM endpoint (no Azure Function). Use it on its own or as a step in a Cloud Events chain for AI reasoning over the JSON flowing between steps.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('`model` is required - call `LLM.Model.List` first to get the model ids available on your endpoint.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('When `tools` are supplied, the named Cloud Events message types are exposed to the model and executed via the dispatcher in a tool loop until the model finishes.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Direction');
        HelpBuilder.AppendLine('Outbound');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Response Content Type');
        HelpBuilder.AppendLine('`text/json`');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Request Parameters');
        HelpBuilder.AppendLine('| Field | Type | Required | Description |');
        HelpBuilder.AppendLine('|-------|------|----------|-------------|');
        HelpBuilder.AppendLine('| model | Text | Yes | Model id, as returned by `LLM.Model.List` |');
        HelpBuilder.AppendLine('| prompt | Text | Yes | The user message content |');
        HelpBuilder.AppendLine('| system | Text | No | System prompt that guides the model |');
        HelpBuilder.AppendLine('| maxTokens | Integer | No | Maximum output tokens (default 4096) |');
        HelpBuilder.AppendLine('| tools | Array | No | Cloud Events message type names to expose as tools |');
        HelpBuilder.AppendLine('| maxToolIterations | Integer | No | Maximum tool-loop turns (default 8) |');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Request Example');
        HelpBuilder.AppendLine('```json');
        HelpBuilder.AppendLine('{');
        HelpBuilder.AppendLine('  "model": "qwen3:8b",');
        HelpBuilder.AppendLine('  "prompt": "Summarize the following data in one sentence: ...",');
        HelpBuilder.AppendLine('  "system": "You are a Business Central assistant.",');
        HelpBuilder.AppendLine('  "maxTokens": 1024,');
        HelpBuilder.AppendLine('  "tools": ["JobQueue.Status.Get"],');
        HelpBuilder.AppendLine('  "maxToolIterations": 8');
        HelpBuilder.AppendLine('}');
        HelpBuilder.AppendLine('```');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Response Shape');
        HelpBuilder.AppendLine('```json');
        HelpBuilder.AppendLine('{');
        HelpBuilder.AppendLine('  "status": "Success",');
        HelpBuilder.AppendLine('  "model": "qwen3:8b",');
        HelpBuilder.AppendLine('  "text": "The assistant response text."');
        HelpBuilder.AppendLine('}');
        HelpBuilder.AppendLine('```');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Tool Loop');
        HelpBuilder.AppendLine('Each tool call from the model runs the named message type via the Cloud Events dispatcher (using the current session permissions), and the result is fed back until the model finishes. A failing tool call is returned to the model as an error rather than aborting the task.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('> **Important**: The model may call a tool more than once. Do not expose irreversible/state-changing message types as tools unless repeated execution is safe.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Errors');
        HelpBuilder.AppendLine('| Condition | Response |');
        HelpBuilder.AppendLine('|-----------|----------|');
        HelpBuilder.AppendLine('| No `model` supplied | `status: Error` with a pointer to `LLM.Model.List` |');
        HelpBuilder.AppendLine('| No `prompt` supplied | `status: Error` |');
        HelpBuilder.AppendLine('| API key not configured | The LLM Service API Key is not set in Cloud Events Setup |');
        HelpBuilder.AppendLine('| LLM API failure | Non-success responses are surfaced with the status and detail |');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Required Permissions');
        HelpBuilder.AppendLine('Execute access to the LLM implementation codeunits, granted by the `Cloud Events LLM` permission set. An LLM **Service API Key** must be configured in Cloud Events Setup, and outbound HttpClient must be allowed for the extension.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Usage Example');
        HelpBuilder.AppendLine('```json');
        HelpBuilder.AppendLine('{');
        HelpBuilder.AppendLine('  "specversion": "1.0",');
        HelpBuilder.AppendLine('  "type": "LLM.Model.Call",');
        HelpBuilder.AppendLine('  "data": "{\\"model\\":\\"qwen3:8b\\",\\"prompt\\":\\"Reply with exactly: connection ok\\"}"');
        HelpBuilder.AppendLine('}');
        HelpBuilder.AppendLine('```');

        HelpText := HelpBuilder.ToText();
    end;
}
