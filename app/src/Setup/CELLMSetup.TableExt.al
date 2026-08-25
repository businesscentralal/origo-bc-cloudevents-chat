namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends Cloud Events Setup with the default LLM provider reference.
/// All provider-specific config (URL, model, keys, timeout) lives on the Provider Setup table.
/// </summary>
tableextension 10035485 "CE LLM Setup ori" extends "Cloud Events Setup ori"
{
    fields
    {
        field(10035489; "CE LLM Def. Provider Code ori"; Code[20])
        {
            Caption = 'Default LLM Provider', Comment = 'is-IS=Sjálfgefin LLM veita';
            DataClassification = CustomerContent;
            TableRelation = "CE LLM Provider Setup ori".Code where(Enabled = const(true));
        }
    }

    /// <summary>
    /// Returns the default provider setup record.
    /// </summary>
    procedure GetDefaultProvider(var ProviderSetup: Record "CE LLM Provider Setup ori"): Boolean
    begin
        if not Rec.Get() then
            exit(false);
        if Rec."CE LLM Def. Provider Code ori" <> '' then
            exit(ProviderSetup.Get(Rec."CE LLM Def. Provider Code ori"));
    end;

    /// <summary>
    /// Returns the default model from the default provider.
    /// </summary>
    procedure GetLLMDefaultModel(): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if GetDefaultProvider(ProviderSetup) then
            exit(ProviderSetup."Default Model");
    end;

    /// <summary>
    /// Returns the base URL from the default provider.
    /// </summary>
    procedure GetLLMBaseUrl(): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        NoProviderErr: Label 'No LLM provider configured. Set a default provider in Cloud Events Setup or on your User Setup.', Comment = 'is-IS=Engin LLM veita stillt. Stilltu sjálfgefna veitu í Uppsetningu atburða í skýinu eða á notandauppsetningu.';
    begin
        if GetDefaultProvider(ProviderSetup) then
            exit(ProviderSetup."Base URL");
        Error(NoProviderErr);
    end;

    /// <summary>
    /// Returns the timeout in milliseconds from the default provider.
    /// </summary>
    procedure GetLLMTimeoutMs(): Integer
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if GetDefaultProvider(ProviderSetup) then
            exit(ProviderSetup.GetTimeoutMs());
        exit(300000);
    end;

    /// <summary>
    /// Returns the max tokens from the default provider.
    /// </summary>
    procedure GetLLMMaxTokens(): Integer
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if GetDefaultProvider(ProviderSetup) then
            exit(ProviderSetup.GetMaxTokens());
        exit(4096);
    end;

    /// <summary>
    /// Returns the service API key from the default provider.
    /// </summary>
    [NonDebuggable]
    procedure GetLLMServiceApiKey(): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if GetDefaultProvider(ProviderSetup) then
            exit(ProviderSetup.GetServiceApiKey());
    end;

    /// <summary>
    /// Returns true if the default provider has a service API key.
    /// </summary>
    procedure HasLLMServiceApiKey(): Boolean
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if GetDefaultProvider(ProviderSetup) then
            exit(ProviderSetup.HasServiceApiKey());
    end;
}
