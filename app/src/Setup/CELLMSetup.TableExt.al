namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends Cloud Events Setup with LLM-specific configuration:
/// base URL, default model for server-side calls, and the service API key.
/// </summary>
tableextension 10035485 "CE LLM Setup ori" extends "Cloud Events Setup ori"
{
    fields
    {
        field(10035485; "CE LLM Base URL ori"; Text[250])
        {
            Caption = 'LLM Base URL', Comment = 'is-IS=LLM grunnvefslóð';
            DataClassification = CustomerContent;
        }
        field(10035486; "CE LLM Default Model ori"; Text[100])
        {
            Caption = 'LLM Default Model', Comment = 'is-IS=Sjálfgefið LLM líkan';
            DataClassification = CustomerContent;
        }
        field(10035487; "CE LLM Timeout ori"; Integer)
        {
            Caption = 'API Timeout (seconds)', Comment = 'is-IS=API tímamörk (sekúndur)';
            DataClassification = SystemMetadata;
            InitValue = 300;
            MinValue = 30;
            MaxValue = 600;
        }
        field(10035488; "CE LLM Max Tokens ori"; Integer)
        {
            Caption = 'Max Output Tokens', Comment = 'is-IS=Hámarks úttaksmerki';
            DataClassification = SystemMetadata;
            InitValue = 4096;
            MinValue = 256;
            MaxValue = 128000;
        }
    }

    var
        ServiceApiKeyTok: Label 'CE_LLM_Service_ApiKey', Locked = true;
        DefaultModelTok: Label 'qwen3:8b', Locked = true;
        DefaultBaseUrlTok: Label 'https://llm.kappi.is', Locked = true;
        ServiceApiKeyMissingErr: Label 'LLM Service API Key is not configured. Set it in Cloud Events Setup.', Comment = 'is-IS=LLM þjónustulykill er ekki stilltur. Stilltu hann í Uppsetning atburða í skýinu.';

    /// <summary>
    /// Stores the LLM service API key in IsolatedStorage (Module scope).
    /// </summary>
    [NonDebuggable]
    procedure SetLLMServiceApiKey(KeyValue: Text)
    begin
        if KeyValue = '' then begin
            if IsolatedStorage.Contains(ServiceApiKeyTok, DataScope::Module) then
                IsolatedStorage.Delete(ServiceApiKeyTok, DataScope::Module);
            exit;
        end;

        IsolatedStorage.Set(ServiceApiKeyTok, KeyValue, DataScope::Module);
    end;

    /// <summary>
    /// Retrieves the LLM service API key from IsolatedStorage. Errors if not configured.
    /// </summary>
    [NonDebuggable]
    procedure GetLLMServiceApiKey() KeyValue: Text
    begin
        if not IsolatedStorage.Get(ServiceApiKeyTok, DataScope::Module, KeyValue) then
            Error(ServiceApiKeyMissingErr);
    end;

    /// <summary>
    /// Returns true if an LLM service API key is stored in IsolatedStorage.
    /// </summary>
    procedure HasLLMServiceApiKey(): Boolean
    begin
        exit(IsolatedStorage.Contains(ServiceApiKeyTok, DataScope::Module));
    end;

    /// <summary>
    /// Returns the configured default LLM model, falling back to a built-in default.
    /// </summary>
    procedure GetLLMDefaultModel(): Text
    begin
        Rec.SetLoadFields("CE LLM Default Model ori");
        Rec.GetRecordOnce();
        if Rec."CE LLM Default Model ori" <> '' then
            exit(Rec."CE LLM Default Model ori");
        exit(DefaultModelTok);
    end;

    /// <summary>
    /// Returns the configured LLM base URL, falling back to the built-in default.
    /// </summary>
    procedure GetLLMBaseUrl(): Text
    begin
        Rec.SetLoadFields("CE LLM Base URL ori");
        Rec.GetRecordOnce();
        if Rec."CE LLM Base URL ori" <> '' then
            exit(Rec."CE LLM Base URL ori");
        exit(DefaultBaseUrlTok);
    end;

    procedure GetLLMTimeoutMs(): Integer
    begin
        Rec.SetLoadFields("CE LLM Timeout ori");
        Rec.GetRecordOnce();
        if Rec."CE LLM Timeout ori" > 0 then
            exit(Rec."CE LLM Timeout ori" * 1000);
        exit(300000); // 5 min default
    end;

    procedure GetLLMMaxTokens(): Integer
    begin
        Rec.SetLoadFields("CE LLM Max Tokens ori");
        Rec.GetRecordOnce();
        if Rec."CE LLM Max Tokens ori" > 0 then
            exit(Rec."CE LLM Max Tokens ori");
        exit(4096);
    end;
}
