namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.Environment;
using System.Environment.Configuration;

/// <summary>
/// Shared logic for LLM provider implementations.
/// Handles role resolution, key management, and config helpers.
/// </summary>
codeunit 10035501 "CE LLM Provider Base ori"
{
    Access = Internal;

    var
        UserKeyPrefixTok: Label 'CE_LLM_Usr_', Locked = true;
        ServiceKeyTok: Label 'CE_LLM_Svc', Locked = true;
        HttpClientBlockedMsg: Label 'HttpClient calls are blocked in this environment. An administrator must allow AL HttpClient requests.', Comment = 'is-IS=HttpClient köll eru lokuð í þessu umhverfi. Stjórnandi þarf að leyfa AL HttpClient beiðnir.';

    /// <summary>
    /// Resolves the current user's MCP Chat Role via CE User Setup fallback chain.
    /// </summary>
    internal procedure GetCurrentRole(var MCPChatRole: Record "MCP Chat Role ori"): Boolean
    var
        CEUserSetup: Record "CE User Setup ori";
        RoleCode: Code[20];
    begin
        CEUserSetup.SetLoadFields("MCP Chat Role Code");
        if CEUserSetup.Get(UserSecurityId()) then
            RoleCode := CEUserSetup."MCP Chat Role Code";

        if RoleCode <> '' then
            if MCPChatRole.Get(RoleCode) then
                exit(true);

        MCPChatRole.SetRange(Default, true);
        exit(MCPChatRole.FindFirst());
    end;

    /// <summary>
    /// Gets the API key: tries user key first, then service key if permitted.
    /// </summary>
    [NonDebuggable]
    internal procedure GetApiKey(): Text
    var
        ApiKeyValue: Text;
    begin
        if IsolatedStorage.Get(UserKeyPrefixTok + Format(UserSecurityId()), DataScope::Company, ApiKeyValue) then
            if ApiKeyValue <> '' then
                exit(ApiKeyValue);

        if HasServiceKeyPermission() then
            if IsolatedStorage.Get(ServiceKeyTok, DataScope::Company, ApiKeyValue) then
                exit(ApiKeyValue);
    end;

    /// <summary>
    /// Saves a per-user API key in IsolatedStorage.
    /// </summary>
    [NonDebuggable]
    internal procedure SaveUserApiKey(ApiKey: Text)
    begin
        if ApiKey = '' then
            IsolatedStorage.Delete(UserKeyPrefixTok + Format(UserSecurityId()), DataScope::Company)
        else
            IsolatedStorage.Set(UserKeyPrefixTok + Format(UserSecurityId()), ApiKey, DataScope::Company);
    end;

    /// <summary>
    /// Saves the shared service API key in IsolatedStorage.
    /// </summary>
    [NonDebuggable]
    internal procedure SaveServiceKey(ApiKey: Text)
    begin
        if ApiKey = '' then
            IsolatedStorage.Delete(ServiceKeyTok, DataScope::Company)
        else
            IsolatedStorage.Set(ServiceKeyTok, ApiKey, DataScope::Company);
    end;

    /// <summary>
    /// Returns whether a service key exists.
    /// </summary>
    internal procedure HasServiceKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ServiceKeyTok, DataScope::Company));
    end;

    /// <summary>
    /// Returns whether the current user has permission to manage the service key.
    /// </summary>
    internal procedure HasServiceKeyPermission(): Boolean
    var
        ServiceGate: Record "CE LLM Service Gate ori";
    begin
        exit(ServiceGate.WritePermission());
    end;

    /// <summary>
    /// Clears the current user's personal API key.
    /// </summary>
    internal procedure ClearUserKey()
    begin
        if IsolatedStorage.Contains(UserKeyPrefixTok + Format(UserSecurityId()), DataScope::Company) then
            IsolatedStorage.Delete(UserKeyPrefixTok + Format(UserSecurityId()), DataScope::Company);
    end;

    /// <summary>
    /// Returns the effective Base URL from role or default.
    /// </summary>
    internal procedure GetBaseUrl(var MCPChatRole: Record "MCP Chat Role ori"; DefaultUrl: Text): Text
    begin
        if MCPChatRole."Base URL" <> '' then
            exit(MCPChatRole."Base URL");
        exit(DefaultUrl);
    end;

    /// <summary>
    /// Returns the effective model from role or default.
    /// </summary>
    internal procedure GetModel(var MCPChatRole: Record "MCP Chat Role ori"; DefaultModel: Text): Text
    begin
        if MCPChatRole.Model <> '' then
            exit(MCPChatRole.Model);
        exit(DefaultModel);
    end;

    /// <summary>
    /// Returns the effective timeout in milliseconds from role or default.
    /// </summary>
    internal procedure GetTimeoutMs(var MCPChatRole: Record "MCP Chat Role ori"; DefaultSeconds: Integer): Integer
    begin
        if MCPChatRole."Timeout Seconds" > 0 then
            exit(MCPChatRole."Timeout Seconds" * 1000);
        exit(DefaultSeconds * 1000);
    end;

    /// <summary>
    /// Returns the effective max tokens from role or default.
    /// </summary>
    internal procedure GetMaxTokens(var MCPChatRole: Record "MCP Chat Role ori"; DefaultMaxTokens: Integer): Integer
    begin
        if MCPChatRole."Max Tokens" > 0 then
            exit(MCPChatRole."Max Tokens");
        exit(DefaultMaxTokens);
    end;

    /// <summary>
    /// Returns whether the provider is minimally configured (key + base URL available).
    /// </summary>
    [NonDebuggable]
    internal procedure IsConfigured(DefaultBaseUrl: Text): Boolean
    var
        MCPChatRole: Record "MCP Chat Role ori";
    begin
        if GetApiKey() = '' then
            exit(false);
        GetCurrentRole(MCPChatRole);
        exit(GetBaseUrl(MCPChatRole, DefaultBaseUrl) <> '');
    end;

    /// <summary>
    /// Parses OpenAI-format token usage from a response JSON string.
    /// </summary>
    internal procedure ParseTokenUsage(ResponseJson: Text; var InputTokens: Integer; var OutputTokens: Integer)
    var
        ResponseObject: JsonObject;
        UsageToken: JsonToken;
        UsageObject: JsonObject;
        PromptToken: JsonToken;
        CompletionToken: JsonToken;
    begin
        InputTokens := 0;
        OutputTokens := 0;
        if not ResponseObject.ReadFrom(ResponseJson) then
            exit;
        if not ResponseObject.Get('usage', UsageToken) then
            exit;
        if not UsageToken.IsObject() then
            exit;
        UsageObject := UsageToken.AsObject();
        if UsageObject.Get('prompt_tokens', PromptToken) then
            InputTokens := PromptToken.AsValue().AsInteger();
        if UsageObject.Get('completion_tokens', CompletionToken) then
            OutputTokens := CompletionToken.AsValue().AsInteger();
    end;

    /// <summary>
    /// Raises an error if HttpClient is not allowed in this environment.
    /// </summary>
    internal procedure EnsureHttpClientAllowed()
    var
        EnvironmentInfo: Codeunit "Environment Information";
        NavApp: Codeunit "NavApp Module Info";
    begin
        if not CanSendHttpRequests() then
            Error(HttpClientBlockedMsg);
    end;

    local procedure CanSendHttpRequests(): Boolean
    var
        Handled: Boolean;
        Allowed: Boolean;
    begin
        OnCheckHttpClientAllowed(Handled, Allowed);
        if Handled then
            exit(Allowed);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckHttpClientAllowed(var Handled: Boolean; var Allowed: Boolean)
    begin
    end;
}
