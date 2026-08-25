namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

codeunit 95903 "CE LLM Provider Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        AIHandler: Codeunit "CE LLM AI Handler ori";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;
        MockProvider.Create();
        MockProvider.SetServiceKey('test-key-12345');
        MockProvider.SetAsDefault();
        if not TryBind() then; // already bound by another test codeunit
        IsInitialized := true;
    end;

    [TryFunction]
    local procedure TryBind()
    begin
        BindSubscription(AIHandler);
    end;

    [Test]
    procedure ProviderSetup_HasApiKey_WithServiceKey()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A mock provider with a service key
        Initialize();

        // [WHEN] We check HasApiKey
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] It reports true (gated access)
        Assert.IsTrue(ProviderSetup.HasApiKey(), 'Expected HasApiKey = true with service key');
    end;

    [Test]
    procedure ProviderSetup_HasApiKey_WithUserKey()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A mock provider with a per-user key
        Initialize();
        MockProvider.SetUserKey('user-key-abc');

        // [WHEN] We check HasApiKey
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] It reports true
        Assert.IsTrue(ProviderSetup.HasApiKey(), 'Expected HasApiKey = true with user key');

        // [CLEANUP]
        MockProvider.SetUserKey('');
    end;

    [Test]
    procedure ProviderSetup_GetApiKey_UserKeyTakesPriority()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        RetrievedKey: Text;
    begin
        // [GIVEN] A provider with both user and service keys
        Initialize();
        MockProvider.SetUserKey('user-key-priority');

        // [WHEN] We get the API key
        MockProvider.GetRecord(ProviderSetup);
        RetrievedKey := ProviderSetup.GetApiKey();

        // [THEN] The user key is returned (takes priority over service key)
        Assert.AreEqual('user-key-priority', RetrievedKey, 'User key should take priority');

        // [CLEANUP]
        MockProvider.SetUserKey('');
    end;

    [Test]
    procedure ProviderSetup_GetChatUrl_BuildsCorrectly()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A provider with base URL and chat path
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] GetChatUrl combines them
        Assert.AreEqual(
            'https://mock.test.local/v1/chat/completions',
            ProviderSetup.GetChatUrl(),
            'Chat URL should be base + path');
    end;

    [Test]
    procedure ProviderSetup_GetModelsUrl_BuildsCorrectly()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A provider with base URL and models path
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] GetModelsUrl combines them
        Assert.AreEqual(
            'https://mock.test.local/v1/models',
            ProviderSetup.GetModelsUrl(),
            'Models URL should be base + path');
    end;

    [Test]
    procedure ProviderSetup_BaseUrl_TrailingSlashRemoved()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A provider
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [WHEN] Base URL is set with trailing slash
        ProviderSetup.Validate("Base URL", 'https://api.example.com/');

        // [THEN] Trailing slash is removed
        Assert.AreEqual('https://api.example.com', ProviderSetup."Base URL", 'Trailing slash should be removed');
    end;

    [Test]
    procedure ProviderList_ReturnsEnabledProviders()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A mock provider that is enabled
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] It appears in the enabled list
        ProviderSetup.SetRange(Enabled, true);
        ProviderSetup.SetRange(Code, MockProvider.GetCode());
        Assert.RecordIsNotEmpty(ProviderSetup);
    end;

    [Test]
    procedure ProviderSetup_DisabledProvider_NotInEnabledFilter()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A mock provider
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [WHEN] We disable it
        ProviderSetup.Enabled := false;
        ProviderSetup.Modify();

        // [THEN] It doesn't appear in enabled filter
        ProviderSetup.SetRange(Enabled, true);
        ProviderSetup.SetRange(Code, MockProvider.GetCode());
        Assert.RecordIsEmpty(ProviderSetup);

        // [CLEANUP]
        ProviderSetup.SetRange(Enabled);
        ProviderSetup.Get(MockProvider.GetCode());
        ProviderSetup.Enabled := true;
        ProviderSetup.Modify();
    end;

    [Test]
    procedure ProviderSetup_ResolveModel_UsesRequestedModel()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A provider with default model
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] Requested model takes priority over default
        Assert.AreEqual('gpt-4o', ProviderSetup.ResolveModel('gpt-4o'), 'Should use requested model');
    end;

    [Test]
    procedure ProviderSetup_ResolveModel_FallsBackToDefault()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A provider with default model 'mock-model-1'
        Initialize();
        MockProvider.GetRecord(ProviderSetup);

        // [THEN] Empty request falls back to default
        Assert.AreEqual('mock-model-1', ProviderSetup.ResolveModel(''), 'Should fall back to default model');
    end;
}
