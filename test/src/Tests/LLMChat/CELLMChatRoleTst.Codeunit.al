namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for role resolution and provider base configuration.
/// </summary>
codeunit 95904 "CE LLM Chat Role Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure GetCurrentRole_DefaultRole_Resolves()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        CEUserSetup: Record "CE User Setup ori";
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
        SavedRoleCode: Code[20];
    begin
        // [GIVEN] Clear any user-level role assignment to test default fallback
        if CEUserSetup.Get(UserSecurityId()) then begin
            SavedRoleCode := CEUserSetup."MCP Chat Role Code";
            CEUserSetup."MCP Chat Role Code" := '';
            CEUserSetup.Modify();
        end;

        // [GIVEN] A mock role set as default
        MockProvider.Create();
        MockProvider.SetAsDefault();

        // [WHEN] Role is resolved
        Assert.IsTrue(ProviderBase.GetCurrentRole(MCPChatRole), 'Should resolve a role');

        // [THEN] It matches the mock role
        Assert.AreEqual(MockProvider.GetCode(), MCPChatRole.Code, 'Resolved role should match default');

        // [CLEANUP]
        MockProvider.Cleanup();
        if CEUserSetup.Get(UserSecurityId()) then begin
            CEUserSetup."MCP Chat Role Code" := SavedRoleCode;
            CEUserSetup.Modify();
        end;
    end;

    [Test]
    procedure HasServiceGate_WithConfiguredRole_ReturnsTrue()
    var
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A mock role with Chat Provider set
        MockProvider.Create();

        // [WHEN/THEN] HasServiceGate returns true
        Assert.IsTrue(ProviderBase.HasServiceGate(), 'Should return true when a role with provider exists');

        // [CLEANUP]
        MockProvider.Cleanup();
    end;

    [Test]
    procedure GetBaseUrl_RoleOverridesDefault()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with a specific Base URL
        MockProvider.Create();
        MockProvider.GetRecord(MCPChatRole);

        // [WHEN] GetBaseUrl is called with a different default
        // [THEN] Role URL takes priority
        Assert.AreEqual('https://mock.test.local', ProviderBase.GetBaseUrl(MCPChatRole, 'https://default.com'), 'Role URL should override default');

        // [CLEANUP]
        MockProvider.Cleanup();
    end;

    [Test]
    procedure GetBaseUrl_EmptyRole_FallsBackToDefault()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with empty Base URL
        MCPChatRole.Init();

        // [WHEN/THEN] Default URL is used
        Assert.AreEqual('https://default.com', ProviderBase.GetBaseUrl(MCPChatRole, 'https://default.com'), 'Should fall back to default');
    end;

    [Test]
    procedure GetModel_RoleOverridesDefault()
    var
        MCPChatRole: Record "MCP Chat Role ori";
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        ProviderBase: Codeunit "CE LLM Provider Base ori";
    begin
        // [GIVEN] A role with a specific model
        MockProvider.Create();
        MockProvider.GetRecord(MCPChatRole);

        // [WHEN/THEN] Role model takes priority
        Assert.AreEqual('mock-model-1', ProviderBase.GetModel(MCPChatRole, 'default-model'), 'Role model should override default');

        // [CLEANUP]
        MockProvider.Cleanup();
    end;
}
