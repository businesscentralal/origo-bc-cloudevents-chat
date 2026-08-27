namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// OpenAI provider implementation using Bearer token authentication.
/// </summary>
codeunit 10035502 "CE LLM OpenAI Impl ori" implements "MCP Chat Role Provider ori"
{
    Access = Internal;

    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
        AuthHeaderNameTok: Label 'Authorization', Locked = true;
        DefaultBaseUrlTok: Label 'https://api.openai.com', Locked = true;
        DefaultModelTok: Label 'gpt-4.1', Locked = true;
        ProviderNameTok: Label 'OpenAI', Locked = true;
        ApiKeyLabelLbl: Label 'API Key', Comment = 'is-IS=API-lykill';
        ApiKeyInstructionLbl: Label 'Enter your OpenAI API key.', Comment = 'is-IS=Sláðu inn OpenAI API-lykilinn þinn.';
        ApiKeyPlaceholderTok: Label 'sk-...', Locked = true;
        ApiKeyDocsUrlTok: Label 'https://platform.openai.com/api-keys', Locked = true;
        ApiKeyDocsLinkTextLbl: Label 'Get key from OpenAI Platform', Comment = 'is-IS=Sækja lykil á OpenAI Platform';
        ServiceKeyDescLbl: Label 'Shared keys are used by all users in this company who do not have a personal key.', Comment = 'is-IS=Sameiginlegir lyklar eru notaðir af öllum notendum í þessu fyrirtæki sem hafa ekki persónulegan lykil.';

    procedure IsConfigured(): Boolean
    begin
        exit(ProviderBase.IsConfigured(DefaultBaseUrlTok));
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
        ConfigJson.Add('model', ProviderBase.GetModel(MCPChatRole, DefaultModelTok));
        ConfigJson.Add('baseUrl', ProviderBase.GetBaseUrl(MCPChatRole, DefaultBaseUrlTok));
        ConfigJson.Add('timeoutMs', ProviderBase.GetTimeoutMs(MCPChatRole, 120));
        ConfigJson.Add('maxTokens', ProviderBase.GetMaxTokens(MCPChatRole, 16384));
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
        exit(LLMChatProxy.SendChatMessage(PayloadJson, AuthHeaderNameTok, DefaultBaseUrlTok, 120, 16384));
    end;

    procedure ContinueWithToolResults(ConversationState: Text; ToolResultsJson: Text): Text
    var
        LLMChatProxy: Codeunit "CE LLM Chat Proxy ori";
    begin
        exit(LLMChatProxy.ContinueWithToolResults(ConversationState, ToolResultsJson, AuthHeaderNameTok, DefaultBaseUrlTok, 120, 16384));
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
        BaseUrl := ProviderBase.GetBaseUrl(MCPChatRole, DefaultBaseUrlTok);
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
        exit(ApiKeyPlaceholderTok);
    end;

    procedure GetApiKeyDocsUrl(): Text
    begin
        exit(ApiKeyDocsUrlTok);
    end;

    procedure GetApiKeyDocsLinkText(): Text
    begin
        exit(ApiKeyDocsLinkTextLbl);
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
        exit(DefaultBaseUrlTok);
    end;

    procedure GetDefaultModel(): Text
    begin
        exit(DefaultModelTok);
    end;

    procedure GetDefaultTimeoutSeconds(): Integer
    begin
        exit(120);
    end;

    procedure GetDefaultMaxTokens(): Integer
    begin
        exit(16384);
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
