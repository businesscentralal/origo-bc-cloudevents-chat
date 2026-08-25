namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for user setup provider resolution and provider configuration.
/// </summary>
codeunit 95904 "CE LLM Chat Role Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure ResolveProvider_UserSetup_ReturnsProvider()
    var
        CEUserSetup: Record "CE User Setup ori";
        ResolvedProvider: Record "CE LLM Provider Setup ori";
        MockProvider: Codeunit "CE LLM Mock Provider ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        // [GIVEN] A mock provider set on user setup
        MockProvider.Create();
        MockProvider.SetServiceKey('test-key');
        if CEUserSetup.Get(UserSecurityId()) then begin
            CEUserSetup."CE LLM Provider Code ori" := MockProvider.GetCode();
            CEUserSetup.Modify();
        end;

        // [WHEN] Provider is resolved
        Assert.IsTrue(LLMChatSetup.ResolveProvider(ResolvedProvider), 'Should resolve a provider');

        // [THEN] It matches the mock provider
        Assert.AreEqual(MockProvider.GetCode(), ResolvedProvider.Code, 'Resolved provider should match user setup');

        // [CLEANUP]
        if CEUserSetup.Get(UserSecurityId()) then begin
            CEUserSetup."CE LLM Provider Code ori" := '';
            CEUserSetup.Modify();
        end;
        MockProvider.Cleanup();
    end;

    [Test]
    procedure ProviderSetup_AuthType_SetsDefaults()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        // [GIVEN] A new provider record
        ProviderSetup.Init();
        ProviderSetup.Code := 'AUTHTEST';

        // [WHEN] Auth Type is set to Bearer
        ProviderSetup.Validate("Auth Type", ProviderSetup."Auth Type"::Bearer);

        // [THEN] Default paths are populated
        Assert.AreEqual('/v1/chat/completions', ProviderSetup."Chat Path", 'Chat path should default');
        Assert.AreEqual('/v1/models', ProviderSetup."Models Path", 'Models path should default');
    end;
}
