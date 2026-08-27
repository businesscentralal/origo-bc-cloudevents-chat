namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Custom/self-hosted LLM provider implementation using x-api-key header authentication.
/// Suitable for Ollama, vLLM, and other OpenAI-compatible endpoints.
/// </summary>
codeunit 10035504 "CE LLM Custom Impl ori" implements "MCP Chat Role Provider ori"
{
    Access = Internal;

    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
        AuthHeaderNameTok: Label 'x-api-key', Locked = true;
        ProviderNameTok: Label 'Custom LLM', Locked = true;
        ApiKeyLabelLbl: Label 'API Key', Comment = 'is-IS=API-lykill';
        ApiKeyInstructionLbl: Label 'Enter the API key for your LLM endpoint.', Comment = 'is-IS=Sláðu inn API-lykilinn fyrir LLM endapunktinn þinn.';
        ServiceKeyDescLbl: Label 'Shared keys are used by all users in this company who do not have a personal key.', Comment = 'is-IS=Sameiginlegir lyklar eru notaðir af öllum notendum í þessu fyrirtæki sem hafa ekki persónulegan lykil.';

    procedure IsConfigured(): Boolean
    begin
        exit(ProviderBase.IsConfigured(''));
    end;

    [NonDebuggable]
    procedure BuildConfigJson(): Text
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ConfigJson: JsonObject;
        ConfigText: Text;
    begin
        ProviderBase.EnsureHttpClientAllowed();
        ProviderBase.GetCurrentRole(MCPChatRole);
        ConfigJson.Add('provider', ProviderNameTok);
        ConfigJson.Add('apiKey', ProviderBase.GetApiKey());
        ConfigJson.Add('model', ProviderBase.GetModel(MCPChatRole, ''));
        ConfigJson.Add('baseUrl', ProviderBase.GetBaseUrl(MCPChatRole, ''));
        ConfigJson.Add('timeoutMs', ProviderBase.GetTimeoutMs(MCPChatRole, 300));
        ConfigJson.Add('maxTokens', ProviderBase.GetMaxTokens(MCPChatRole, 8192));
        ConfigJson.WriteTo(ConfigText);
        exit(ConfigText);
    end;

    [NonDebuggable]
    procedure SaveApiKey(ApiKey: Text)
    begin
        ProviderBase.SaveUserApiKey(ApiKey);
    end;

    procedure SendChatMessage(PayloadJson: Text): Text
    var
        LLMChatProxy: Codeunit "CE LLM Chat Proxy ori";
    begin
        exit(LLMChatProxy.SendChatMessage(PayloadJson, AuthHeaderNameTok, '', 300, 8192));
    end;

    procedure ContinueWithToolResults(ConversationState: Text; ToolResultsJson: Text): Text
    var
        LLMChatProxy: Codeunit "CE LLM Chat Proxy ori";
    begin
        exit(LLMChatProxy.ContinueWithToolResults(ConversationState, ToolResultsJson, AuthHeaderNameTok, '', 300, 8192));
    end;

    procedure GetAvailableModels(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ApiClient: Codeunit "CE LLM API Client ori";
        ModelsArray: JsonArray;
        ModelToken: JsonToken;
        ModelObject: JsonObject;
        BaseUrl: Text;
        IdValue: Text;
        EntryNo: Integer;
    begin
        ProviderBase.GetCurrentRole(MCPChatRole);
        BaseUrl := ProviderBase.GetBaseUrl(MCPChatRole, '');
        if BaseUrl = '' then
            exit(false);

        ModelsArray := ApiClient.ListModelsFromEndpoint(BaseUrl + '/v1/models', AuthHeaderNameTok, ProviderBase.GetApiKey());

        foreach ModelToken in ModelsArray do begin
            ModelObject := ModelToken.AsObject();
            IdValue := GetJsonText(ModelObject, 'id');
            if IdValue <> '' then begin
                EntryNo += 1;
                TempNameValueBuffer.Init();
                TempNameValueBuffer.ID := EntryNo;
                TempNameValueBuffer.Name := CopyStr(IdValue, 1, MaxStrLen(TempNameValueBuffer.Name));
                TempNameValueBuffer.Value := CopyStr(IdValue, 1, MaxStrLen(TempNameValueBuffer.Value));
                TempNameValueBuffer.Insert();
            end;
        end;
        exit(EntryNo > 0);
    end;

    procedure ClearCredentials()
    begin
        ProviderBase.ClearUserKey();
    end;

    procedure GetProviderName(): Text
    begin
        exit(ProviderNameTok);
    end;

    procedure RequiresApiKey(): Boolean
    begin
        exit(true);
    end;

    procedure GetApiKeyLabel(): Text
    begin
        exit(ApiKeyLabelLbl);
    end;

    procedure GetApiKeyInstruction(): Text
    begin
        exit(ApiKeyInstructionLbl);
    end;

    procedure GetApiKeyPlaceholder(): Text
    begin
        exit('');
    end;

    procedure GetApiKeyDocsUrl(): Text
    begin
        exit('');
    end;

    procedure GetApiKeyDocsLinkText(): Text
    begin
        exit('');
    end;

    procedure GetServiceKeyDescription(): Text
    begin
        exit(ServiceKeyDescLbl);
    end;

    procedure HasServiceApiKey(): Boolean
    begin
        exit(ProviderBase.HasServiceKey());
    end;

    [NonDebuggable]
    procedure SaveServiceApiKey(ApiKey: Text)
    begin
        ProviderBase.SaveServiceKey(ApiKey);
    end;

    procedure HasServiceKeyPermission(): Boolean
    begin
        exit(ProviderBase.HasServiceKeyPermission());
    end;

    procedure GetMaxToolCount(): Integer
    begin
        exit(0);
    end;

    procedure SupportsSplitToolExecution(): Boolean
    begin
        exit(true);
    end;

    procedure SupportsModelSelection(): Boolean
    begin
        exit(true);
    end;

    procedure SupportsToolCalling(): Boolean
    begin
        exit(true);
    end;

    procedure HasExternalEndpoint(): Boolean
    begin
        exit(true);
    end;

    procedure GetDefaultBaseUrl(): Text
    begin
        exit('');
    end;

    procedure GetDefaultModel(): Text
    begin
        exit('');
    end;

    procedure GetDefaultTimeoutSeconds(): Integer
    begin
        exit(300);
    end;

    procedure GetDefaultMaxTokens(): Integer
    begin
        exit(8192);
    end;

    procedure GetContextWindowChars(): Integer
    begin
        exit(80000);
    end;

    procedure GetTokenUsage(ResponseJson: Text; var InputTokens: Integer; var OutputTokens: Integer)
    begin
        ProviderBase.ParseTokenUsage(ResponseJson, InputTokens, OutputTokens);
    end;

    local procedure GetJsonText(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(PropertyName, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
    end;
}
