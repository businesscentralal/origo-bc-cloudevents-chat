namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using Microsoft.Utilities;

/// <summary>
/// Azure OpenAI provider implementation using api-key header authentication.
/// </summary>
codeunit 10035503 "CE LLM Azure OAI Impl ori" implements "MCP Chat Role Provider ori"
{
    Access = Internal;

    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
        AuthHeaderNameTok: Label 'api-key', Locked = true;
        ProviderNameTok: Label 'Azure OpenAI', Locked = true;
        ApiKeyLabelLbl: Label 'API Key', Comment = 'is-IS=API-lykill';
        ApiKeyInstructionLbl: Label 'Enter your Azure OpenAI deployment API key.', Comment = 'is-IS=Sláðu inn Azure OpenAI API-lykilinn þinn.';
        ApiKeyDocsUrlTok: Label 'https://portal.azure.com', Locked = true;
        ApiKeyDocsLinkTextLbl: Label 'Azure Portal', Comment = 'is-IS=Azure Portal';
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
        exit(LLMChatProxy.SendChatMessage(PayloadJson));
    end;

    procedure ContinueWithToolResults(ConversationState: Text; ToolResultsJson: Text): Text
    var
        LLMChatProxy: Codeunit "CE LLM Chat Proxy ori";
    begin
        exit(LLMChatProxy.ContinueWithToolResults(ConversationState, ToolResultsJson));
    end;

    procedure GetAvailableModels(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    begin
        // Azure OpenAI does not support /v1/models listing; model = deployment name
        exit(false);
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
        exit(false);
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
}
