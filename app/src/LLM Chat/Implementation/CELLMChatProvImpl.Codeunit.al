namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// LLM implementation of the "MCP Chat Provider" interface.
/// Delegates every backend operation to the existing "LLM Chat Setup"
/// and "LLM Chat Proxy" codeunits so the base MCP chat pages and
/// control add-in can drive the LLM without referencing it directly.
/// </summary>
codeunit 10035486 "CE LLM Chat Prov Impl ori" implements "MCP Chat Provider ori"
{
    Access = Internal;

    /// <summary>
    /// Returns true when the current user has an LLM provider configured.
    /// </summary>
    procedure IsConfigured(): Boolean
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        exit(LLMChatSetup.ResolveProvider(ProviderSetup));
    end;

    /// <summary>
    /// Builds the control add-in configuration JSON for the LLM provider.
    /// </summary>
    [NonDebuggable]
    procedure BuildConfigJson(): Text
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        LLMChatSetup.EnsureHttpClientAllowed();
        exit(LLMChatSetup.BuildConfigJson());
    end;

    /// <summary>
    /// Persists the LLM API key in IsolatedStorage.
    /// </summary>
    [NonDebuggable]
    procedure SaveApiKey(ApiKey: Text)
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        LLMChatSetup.SetApiKey(ApiKey);
    end;

    /// <summary>
    /// Persists the OAuth connection payload for the LLM provider.
    /// </summary>
    [NonDebuggable]
    procedure SaveConnectionData(ConnectionDataJson: Text)
    begin
        // No connection data needed for direct API key auth
    end;

    /// <summary>
    /// Forwards a chat payload to the LLM backend proxy and returns the JSON response.
    /// </summary>
    [NonDebuggable]
    procedure SendChatMessage(PayloadJson: Text): Text
    var
        LLMChatProxy: Codeunit "CE LLM Chat Proxy ori";
    begin
        exit(LLMChatProxy.SendChatMessage(PayloadJson));
    end;

    [NonDebuggable]
    procedure ContinueWithToolResults(ConversationState: Text; ToolResultsJson: Text): Text
    var
        LLMChatProxy: Codeunit "CE LLM Chat Proxy ori";
    begin
        exit(LLMChatProxy.ContinueWithToolResults(ConversationState, ToolResultsJson));
    end;

    /// <summary>
    /// Fetches the list of models from the LLM endpoint.
    /// </summary>
    procedure GetAvailableModels(var TempNameValueBuffer: Record "Name/Value Buffer" temporary): Boolean
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        exit(LLMChatSetup.GetAvailableModels(TempNameValueBuffer));
    end;

    /// <summary>
    /// Clears the stored LLM API key for the current user.
    /// </summary>
    procedure ClearCredentials()
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        LLMChatSetup.ClearCredentials();
    end;
}
