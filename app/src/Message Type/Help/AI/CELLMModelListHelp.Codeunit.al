namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Provides runtime help documentation for the LLM.Model.List message type.
/// </summary>
codeunit 10035494 "CE LLM Model List Help ori"
{
    Access = Internal;

    /// <summary>
    /// Returns help text for the LLM.Model.List message type in Markdown format.
    /// </summary>
    internal procedure GetHelpText() HelpText: Text
    var
        HelpBuilder: TextBuilder;
    begin
        HelpBuilder.AppendLine('# LLM.Model.List');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Overview');
        HelpBuilder.AppendLine('Lists the models available on the configured LLM endpoint. Use this to discover a valid `model` id before calling `LLM.Model.Call`, which requires one.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Direction');
        HelpBuilder.AppendLine('Outbound');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Response Content Type');
        HelpBuilder.AppendLine('`text/json`');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Request Parameters');
        HelpBuilder.AppendLine('None required.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Response Shape');
        HelpBuilder.AppendLine('```json');
        HelpBuilder.AppendLine('{');
        HelpBuilder.AppendLine('  "status": "Success",');
        HelpBuilder.AppendLine('  "noOfRecords": 1,');
        HelpBuilder.AppendLine('  "defaultModel": "qwen3:8b",');
        HelpBuilder.AppendLine('  "result": [');
        HelpBuilder.AppendLine('    { "id": "qwen3:8b", "object": "model" }');
        HelpBuilder.AppendLine('  ]');
        HelpBuilder.AppendLine('}');
        HelpBuilder.AppendLine('```');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('`defaultModel` is the model configured in Cloud Events Setup, used by the chat provider when a role does not specify one.');
        HelpBuilder.AppendLine('');
        HelpBuilder.AppendLine('## Errors');
        HelpBuilder.AppendLine('| Condition | Response |');
        HelpBuilder.AppendLine('|-----------|----------|');
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
        HelpBuilder.AppendLine('  "type": "LLM.Model.List",');
        HelpBuilder.AppendLine('  "data": "{}"');
        HelpBuilder.AppendLine('}');
        HelpBuilder.AppendLine('```');

        HelpText := HelpBuilder.ToText();
    end;
}
