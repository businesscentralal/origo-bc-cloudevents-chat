namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the Provider.List message type.
/// Returns all enabled LLM providers with their codes and configuration summary.
/// </summary>
codeunit 10035497 "CE LLM Provider List Impl ori" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    var
        ProviderListHelpLbl: Label 'Returns all enabled LLM providers with their codes, names, and default models.', Comment = 'is-IS=Skilar öllum virkum LLM veitum með kóðum, heitum og sjálfgefnum líkönum.';

    internal procedure IsEnabled(): Boolean
    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        exit(ProviderBase.HasServiceGate());
    end;

    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    internal procedure GetDescription() Description: Text[250]
    begin
        exit(CopyStr(ProviderListHelpLbl, 1, MaxStrLen(Description)));
    end;

    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        Help: TextBuilder;
    begin
        Help.AppendLine('# Provider.List');
        Help.AppendLine('');
        Help.AppendLine('Returns all enabled LLM providers.');
        Help.AppendLine('');
        Help.AppendLine('## Request');
        Help.AppendLine('No parameters required. Send an empty JSON object `{}`.');
        Help.AppendLine('');
        Help.AppendLine('## Response');
        Help.AppendLine('```json');
        Help.AppendLine('{');
        Help.AppendLine('  "status": "Success",');
        Help.AppendLine('  "noOfRecords": 3,');
        Help.AppendLine('  "result": [');
        Help.AppendLine('    { "code": "OLLAMA", "name": "Ollama", "baseUrl": "https://llm.kappi.is", "defaultModel": "qwen3:8b", "authType": "x-api-key" },');
        Help.AppendLine('    { "code": "OPENAI", "name": "OpenAI", "baseUrl": "https://api.openai.com", "defaultModel": "gpt-4o", "authType": "Bearer" }');
        Help.AppendLine('  ]');
        Help.AppendLine('}');
        Help.AppendLine('```');
        Argument.SetResponseMarkdown(Help.ToText());
    end;

    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
        ResponseJson: JsonObject;
        ProvidersArray: JsonArray;
        ProviderJson: JsonObject;
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not ProviderBase.AssertServiceGate(Argument) then
            exit;

        MCPChatRole.SetFilter("Chat Provider", '<>%1', MCPChatRole."Chat Provider"::None);
        if MCPChatRole.FindSet() then
            repeat
                Clear(ProviderJson);
                ProviderJson.Add('code', MCPChatRole.Code);
                ProviderJson.Add('name', MCPChatRole.Description);
                ProviderJson.Add('baseUrl', MCPChatRole."Base URL");
                ProviderJson.Add('defaultModel', MCPChatRole.Model);
                ProviderJson.Add('chatProvider', Format(MCPChatRole."Chat Provider"));
                ProvidersArray.Add(ProviderJson);
            until MCPChatRole.Next() = 0;

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('noOfRecords', ProvidersArray.Count());
        ResponseJson.Add('result', ProvidersArray);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;
}
