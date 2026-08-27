namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for API key management via ProviderBase.
/// </summary>
codeunit 95903 "CE LLM Provider Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        IsInitialized: Boolean;

    local procedure Initialize()
    var
        CEUserSetup: Record "CE User Setup ori";
    begin
        if IsInitialized then
            exit;
        // Clear user-level role to ensure default role resolution
        if CEUserSetup.Get(UserSecurityId()) then begin
            CEUserSetup."MCP Chat Role Code" := '';
            CEUserSetup.Modify();
        end;
        MockProvider.Create();
        MockProvider.SetServiceKey('test-key-12345');
        MockProvider.SetAsDefault();
        IsInitialized := true;
    end;

    [Test]
    procedure GetApiKey_WithUserKey_ReturnsUserKey()
    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A mock role with a per-user key
        Initialize();
        MockProvider.SetUserKey('user-key-abc');

        // [WHEN/THEN] GetApiKey returns the user key
        Assert.AreEqual('user-key-abc', ProviderBase.GetApiKey(), 'Should return user key');

        // [CLEANUP]
        MockProvider.SetUserKey('');
    end;

    [Test]
    procedure GetApiKey_UserKeyTakesPriority()
    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] Both user and service keys exist
        Initialize();
        MockProvider.SetUserKey('user-key-priority');

        // [WHEN/THEN] User key takes priority
        Assert.AreEqual('user-key-priority', ProviderBase.GetApiKey(), 'User key should take priority over service key');

        // [CLEANUP]
        MockProvider.SetUserKey('');
    end;

    [Test]
    procedure IsConfigured_WithKeyAndUrl_ReturnsTrue()
    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A configured role with service key and base URL
        Initialize();

        // [WHEN/THEN] IsConfigured returns true
        Assert.IsTrue(ProviderBase.IsConfigured(''), 'Should be configured with key and URL');
    end;

    [Test]
    procedure IsConfigured_WithoutKey_ReturnsFalse()
    var
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] No keys stored (fresh state, no Initialize)
        ProviderBase.SaveUserApiKey('');
        ProviderBase.SaveServiceKey('');

        // [WHEN/THEN] IsConfigured returns false without any key
        Assert.IsFalse(ProviderBase.IsConfigured('https://mock.test.local'), 'Should not be configured without key');

        // [CLEANUP] — restore for other tests
        ProviderBase.SaveServiceKey('test-key-12345');
    end;

    [Test]
    procedure GetTimeoutMs_RoleValue_Converts()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with timeout = 60 seconds
        Initialize();
        MockProvider.GetRecord(MCPChatRole);

        // [WHEN/THEN] GetTimeoutMs returns milliseconds
        Assert.AreEqual(60000, ProviderBase.GetTimeoutMs(MCPChatRole, 120), 'Should convert 60s to 60000ms');
    end;

    [Test]
    procedure GetTimeoutMs_ZeroRole_UsesDefault()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with timeout = 0
        MCPChatRole.Init();

        // [WHEN/THEN] Default is used
        Assert.AreEqual(120000, ProviderBase.GetTimeoutMs(MCPChatRole, 120), 'Should use default 120s = 120000ms');
    end;

    [Test]
    procedure GetMaxTokens_RoleValue_Used()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with max tokens = 2048
        Initialize();
        MockProvider.GetRecord(MCPChatRole);

        // [WHEN/THEN] Role value is used
        Assert.AreEqual(2048, ProviderBase.GetMaxTokens(MCPChatRole, 4096), 'Should use role value');
    end;

    [Test]
    procedure GetMaxTokens_ZeroRole_UsesDefault()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with max tokens = 0
        MCPChatRole.Init();

        // [WHEN/THEN] Default is used
        Assert.AreEqual(4096, ProviderBase.GetMaxTokens(MCPChatRole, 4096), 'Should use default');
    end;
}
