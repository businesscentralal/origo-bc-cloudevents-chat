namespace Origo.APP.CloudEvents.LLM;

using System.Utilities;

/// <summary>
/// Stores configuration for each LLM provider endpoint.
/// One record per provider (e.g., Ollama, OpenAI, Grok, Azure Foundry).
/// Service API keys are stored in IsolatedStorage keyed by provider code.
/// </summary>
table 10035496 "CE LLM Provider Setup ori"
{
    Access = Public;
    Caption = 'LLM Provider Setup', Comment = 'is-IS=Uppsetning LLM veitu';
    DataClassification = CustomerContent;
    LookupPageId = "CE LLM Provider List ori";
    DrillDownPageId = "CE LLM Provider List ori";

    fields
    {
        field(1; "Code"; Code[20])
        {
            Caption = 'Code', Comment = 'is-IS=Kóði';
            DataClassification = CustomerContent;
            NotBlank = true;
        }
        field(2; "Name"; Text[100])
        {
            Caption = 'Name', Comment = 'is-IS=Heiti';
            DataClassification = CustomerContent;
        }
        field(3; "Base URL"; Text[250])
        {
            Caption = 'Base URL', Comment = 'is-IS=Grunnvefslóð';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                UriCu: Codeunit Uri;
                Scheme: Text;
            begin
                if "Base URL" = '' then
                    exit;
                if "Base URL".EndsWith('/') then
                    "Base URL" := CopyStr(CopyStr("Base URL", 1, StrLen("Base URL") - 1), 1, MaxStrLen("Base URL"));
                if not UriCu.IsValidUri("Base URL") then
                    Error(InvalidUrlErr, "Base URL");
                UriCu.Init("Base URL");
                Scheme := UriCu.GetScheme();
                if not (Scheme in ['https', 'http']) then
                    Error(InvalidSchemeErr);
            end;
        }
        field(4; "Auth Type"; Enum "CE LLM Auth Type ori")
        {
            Caption = 'Auth Type', Comment = 'is-IS=Auðkenningartegund';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                AuthConfig: Interface "CE LLM Auth Config ori";
            begin
                AuthConfig := "Auth Type";
                if "Base URL" = '' then
                    "Base URL" := AuthConfig.GetDefaultBaseUrl();
                if "Chat Path" = '' then
                    "Chat Path" := AuthConfig.GetDefaultChatPath();
                if "Models Path" = '' then
                    "Models Path" := AuthConfig.GetDefaultModelsPath();
                if "Timeout Seconds" = 0 then
                    "Timeout Seconds" := AuthConfig.GetDefaultTimeout();
                if "Max Tokens" = 0 then
                    "Max Tokens" := AuthConfig.GetDefaultMaxTokens();
                if "Default Model" = '' then
                    "Default Model" := AuthConfig.GetDefaultModel();
            end;
        }
        field(5; "Default Model"; Text[100])
        {
            Caption = 'Default Model', Comment = 'is-IS=Sjálfgefið líkan';
            DataClassification = CustomerContent;
        }
        field(6; "Timeout Seconds"; Integer)
        {
            Caption = 'Timeout (seconds)', Comment = 'is-IS=Tímamörk (sekúndur)';
            DataClassification = SystemMetadata;
            InitValue = 300;
            MinValue = 30;
            MaxValue = 600;
        }
        field(7; "Max Tokens"; Integer)
        {
            Caption = 'Max Output Tokens', Comment = 'is-IS=Hámarks úttaksmerki';
            DataClassification = SystemMetadata;
            InitValue = 4096;
            MinValue = 256;
            MaxValue = 128000;
        }
        field(8; "Chat Path"; Text[100])
        {
            Caption = 'Chat Completions Path', Comment = 'is-IS=Spjallslóð';
            DataClassification = CustomerContent;
            InitValue = '/v1/chat/completions';
        }
        field(9; "Models Path"; Text[100])
        {
            Caption = 'Models Path', Comment = 'is-IS=Líkanslóð';
            DataClassification = CustomerContent;
            InitValue = '/v1/models';
        }
        field(10; Enabled; Boolean)
        {
            Caption = 'Enabled', Comment = 'is-IS=Virkt';
            DataClassification = SystemMetadata;
            InitValue = false;
        }
    }

    keys
    {
        key(PK; "Code")
        {
            Clustered = true;
        }
        key(Name; "Name") { }
    }

    trigger OnDelete()
    begin
        SetServiceApiKey('');
        SetUserApiKey('');
    end;

    var
        ServiceKeyPrefixTok: Label 'CE_LLM_Svc_%1', Locked = true;
        UserKeyPrefixTok: Label 'CE_LLM_Usr_%1', Locked = true;
        InvalidUrlErr: Label '''%1'' is not a valid URL. Include the scheme (e.g. https://api.openai.com).', Comment = '%1 = url, is-IS=''%1'' er ekki gild vefslóð. Hafðu skemað með (t.d. https://api.openai.com).';
        InvalidSchemeErr: Label 'Base URL must use https:// or http:// scheme.', Comment = 'is-IS=Grunnvefslóð verður að nota https:// eða http:// skema.';

    /// <summary>
    /// Stores the shared service API key for this provider (Module scope, gated).
    /// </summary>
    [NonDebuggable]
    procedure SetServiceApiKey(KeyValue: Text)
    var
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(ServiceKeyPrefixTok, Code);
        if KeyValue = '' then begin
            if IsolatedStorage.Contains(StorageKey, DataScope::Module) then
                IsolatedStorage.Delete(StorageKey, DataScope::Module);
            exit;
        end;
        IsolatedStorage.Set(StorageKey, KeyValue, DataScope::Module);
    end;

    /// <summary>
    /// Retrieves the shared service API key for this provider.
    /// </summary>
    [NonDebuggable]
    procedure GetServiceApiKey() KeyValue: Text
    var
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(ServiceKeyPrefixTok, Code);
        IsolatedStorage.Get(StorageKey, DataScope::Module, KeyValue);
    end;

    procedure HasServiceApiKey(): Boolean
    var
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(ServiceKeyPrefixTok, Code);
        exit(IsolatedStorage.Contains(StorageKey, DataScope::Module));
    end;

    /// <summary>
    /// Stores a per-user API key for this provider (User scope).
    /// </summary>
    [NonDebuggable]
    procedure SetUserApiKey(KeyValue: Text)
    var
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(UserKeyPrefixTok, Code);
        if KeyValue = '' then begin
            if IsolatedStorage.Contains(StorageKey, DataScope::User) then
                IsolatedStorage.Delete(StorageKey, DataScope::User);
            exit;
        end;
        IsolatedStorage.Set(StorageKey, KeyValue, DataScope::User);
    end;

    /// <summary>
    /// Retrieves the per-user API key, falling back to the service key if gated.
    /// </summary>
    [NonDebuggable]
    procedure GetApiKey(): Text
    var
        ServiceGate: Record "CE LLM Service Gate ori";
        StorageKey: Text;
        KeyValue: Text;
    begin
        StorageKey := StrSubstNo(UserKeyPrefixTok, Code);
        if IsolatedStorage.Get(StorageKey, DataScope::User, KeyValue) then
            exit(KeyValue);
        if ServiceGate.WritePermission() then
            exit(GetServiceApiKey());
    end;

    procedure HasApiKey(): Boolean
    var
        ServiceGate: Record "CE LLM Service Gate ori";
        StorageKey: Text;
    begin
        StorageKey := StrSubstNo(UserKeyPrefixTok, Code);
        if IsolatedStorage.Contains(StorageKey, DataScope::User) then
            exit(true);
        exit(ServiceGate.WritePermission() and HasServiceApiKey());
    end;

    /// <summary>
    /// Returns the full chat completions URL for this provider.
    /// </summary>
    procedure GetChatUrl(): Text
    begin
        if "Chat Path" <> '' then
            exit("Base URL" + "Chat Path");
        exit("Base URL" + '/v1/chat/completions');
    end;

    /// <summary>
    /// Returns the full models list URL for this provider.
    /// </summary>
    procedure GetModelsUrl(): Text
    begin
        if "Models Path" <> '' then
            exit("Base URL" + "Models Path");
        exit("Base URL" + '/v1/models');
    end;

    /// <summary>
    /// Returns the timeout in milliseconds.
    /// </summary>
    procedure GetTimeoutMs(): Integer
    begin
        if "Timeout Seconds" > 0 then
            exit("Timeout Seconds" * 1000);
        exit(300000);
    end;

    /// <summary>
    /// Returns the max tokens setting, defaulting to 4096.
    /// </summary>
    procedure GetMaxTokens(): Integer
    begin
        if "Max Tokens" > 0 then
            exit("Max Tokens");
        exit(4096);
    end;

    /// <summary>
    /// Returns the model to use, falling back to the provider default.
    /// </summary>
    procedure ResolveModel(RequestedModel: Text): Text
    begin
        if RequestedModel <> '' then
            exit(RequestedModel);
        exit("Default Model");
    end;

    /// <summary>
    /// Adds the provider's auth header to the HTTP client using the interface implementation.
    /// </summary>
    [NonDebuggable]
    procedure ApplyAuthHeader(var HttpClient: HttpClient; ApiKey: Text)
    var
        AuthConfig: Interface "CE LLM Auth Config ori";
    begin
        AuthConfig := "Auth Type";
        AuthConfig.AddAuthHeader(HttpClient, ApiKey);
    end;
}
