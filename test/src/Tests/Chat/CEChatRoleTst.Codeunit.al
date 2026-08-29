namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for role resolution and provider base helpers.
/// </summary>
codeunit 95904 "CE Chat Role Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure HasServiceGate_WithConfiguredRole_ReturnsTrue()
    var
        MockProvider: Codeunit "CE Chat Mock Provider ori";
        ProviderBase: Codeunit "CE Chat Provider Base ori";
    begin
        MockProvider.Create();
        Assert.IsTrue(ProviderBase.HasServiceGate(), 'Should return true when a role with provider exists');
        MockProvider.Cleanup();
    end;

    [Test]
    procedure GetBaseUrl_RoleOverridesDefault()
    var
        MockProvider: Codeunit "CE Chat Mock Provider ori";
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        MockProvider.Create();
        MockProvider.BuildArgument(TempArg);
        Assert.AreEqual('https://mock.test.local', ProviderBase.GetBaseUrl(TempArg, 'https://default.com'),
            'Role URL should override default');
        MockProvider.Cleanup();
    end;

    [Test]
    procedure GetBaseUrl_EmptyRole_FallsBackToDefault()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        TempArg.Init();
        Assert.AreEqual('https://default.com', ProviderBase.GetBaseUrl(TempArg, 'https://default.com'),
            'Should fall back to default');
    end;

    [Test]
    procedure GetModel_RoleOverridesDefault()
    var
        MockProvider: Codeunit "CE Chat Mock Provider ori";
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        MockProvider.Create();
        MockProvider.BuildArgument(TempArg);
        Assert.AreEqual('mock-model-1', ProviderBase.GetModel(TempArg, 'default-model'),
            'Role model should override default');
        MockProvider.Cleanup();
    end;
}
