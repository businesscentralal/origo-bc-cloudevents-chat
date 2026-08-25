namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Creates and manages a mock LLM provider for testing.
/// Inserts a test provider record with known values and provides
/// helpers to set up per-user and service keys.
/// </summary>
codeunit 95902 "CE LLM Mock Provider ori"
{
    Access = Internal;
    Permissions = tabledata "CE LLM Provider Setup ori" = RIMD,
                  tabledata "CE LLM Service Gate ori" = RIMD,
                  tabledata "Cloud Events Setup ori" = RIMD;

    var
        MockProviderCode: Code[20];

    /// <summary>
    /// Creates a mock provider with predictable settings. Returns the provider code.
    /// </summary>
    procedure Create(): Code[20]
    begin
        exit(CreateWithCode('MOCK'));
    end;

    procedure CreateWithCode(ProviderCode: Code[20]): Code[20]
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        MockProviderCode := ProviderCode;
        if ProviderSetup.Get(MockProviderCode) then
            ProviderSetup.Delete();

        ProviderSetup.Init();
        ProviderSetup.Code := MockProviderCode;
        ProviderSetup.Name := 'Mock LLM Provider';
        ProviderSetup."Base URL" := 'https://mock.test.local';
        ProviderSetup."Auth Type" := ProviderSetup."Auth Type"::"x-api-key";
        ProviderSetup."Default Model" := 'mock-model-1';
        ProviderSetup."Timeout Seconds" := 60;
        ProviderSetup."Max Tokens" := 2048;
        ProviderSetup."Chat Path" := '/v1/chat/completions';
        ProviderSetup."Models Path" := '/v1/models';
        ProviderSetup.Enabled := true;
        ProviderSetup.Insert();

        exit(MockProviderCode);
    end;

    /// <summary>
    /// Sets a per-user API key on the mock provider.
    /// </summary>
    procedure SetUserKey(ApiKey: Text)
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        ProviderSetup.Get(MockProviderCode);
        ProviderSetup.SetUserApiKey(ApiKey);
    end;

    /// <summary>
    /// Sets the shared service API key on the mock provider.
    /// </summary>
    procedure SetServiceKey(ApiKey: Text)
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        ProviderSetup.Get(MockProviderCode);
        ProviderSetup.SetServiceApiKey(ApiKey);
    end;

    /// <summary>
    /// Sets the mock provider as the default in Cloud Events Setup.
    /// </summary>
    procedure SetAsDefault()
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if not CloudEventsSetup.Get() then begin
            CloudEventsSetup.Init();
            CloudEventsSetup.Insert();
        end;
        CloudEventsSetup."CE LLM Def. Provider Code ori" := MockProviderCode;
        CloudEventsSetup.Modify();
    end;

    /// <summary>
    /// Returns the mock provider code.
    /// </summary>
    procedure GetCode(): Code[20]
    begin
        exit(MockProviderCode);
    end;

    /// <summary>
    /// Returns the mock provider record.
    /// </summary>
    procedure GetRecord(var ProviderSetup: Record "CE LLM Provider Setup ori")
    begin
        ProviderSetup.Get(MockProviderCode);
    end;

    /// <summary>
    /// Removes the mock provider and cleans up keys.
    /// </summary>
    procedure Cleanup()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if ProviderSetup.Get(MockProviderCode) then begin
            ProviderSetup.SetUserApiKey('');
            ProviderSetup.SetServiceApiKey('');
            ProviderSetup.Delete();
        end;
    end;
}
