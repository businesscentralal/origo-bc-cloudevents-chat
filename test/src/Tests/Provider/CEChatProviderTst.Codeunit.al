namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for provider base configuration helpers using MCP Chat Argument.
/// </summary>
codeunit 95903 "CE Chat Provider Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure IsConfigured_WithKeyAndUrl_ReturnsTrue()
    var
        MockProvider: Codeunit "CE Chat Mock Provider ori";
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        MockProvider.Create();
        MockProvider.BuildArgumentWithKey(TempArg, 'test-key');
        Assert.IsTrue(ProviderBase.IsConfigured(TempArg, ''), 'Should be configured with key and URL');
        MockProvider.Cleanup();
    end;

    [Test]
    procedure IsConfigured_WithoutKey_ReturnsFalse()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        TempArg.Init();
        TempArg."Base URL" := 'https://mock.test.local';
        Assert.IsFalse(ProviderBase.IsConfigured(TempArg, ''), 'Should not be configured without key');
    end;

    [Test]
    procedure IsConfigured_WithKeyNoUrl_UsesDefault()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        TempArg.Init();
        TempArg.SetApiKey('some-key');
        Assert.IsTrue(ProviderBase.IsConfigured(TempArg, 'https://default.com'),
            'Should be configured with key and default URL');
    end;

    [Test]
    procedure GetTimeoutMs_RoleValue_Converts()
    var
        MockProvider: Codeunit "CE Chat Mock Provider ori";
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        MockProvider.Create();
        MockProvider.BuildArgument(TempArg);
        Assert.AreEqual(60000, ProviderBase.GetTimeoutMs(TempArg, 120000), 'Should use role timeout 60s = 60000ms');
        MockProvider.Cleanup();
    end;

    [Test]
    procedure GetTimeoutMs_ZeroRole_UsesDefault()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        TempArg.Init();
        Assert.AreEqual(120000, ProviderBase.GetTimeoutMs(TempArg, 120000), 'Should use default');
    end;

    [Test]
    procedure GetMaxTokens_RoleValue_Used()
    var
        MockProvider: Codeunit "CE Chat Mock Provider ori";
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        MockProvider.Create();
        MockProvider.BuildArgument(TempArg);
        Assert.AreEqual(2048, ProviderBase.GetMaxTokens(TempArg, 4096), 'Should use role value');
        MockProvider.Cleanup();
    end;

    [Test]
    procedure GetMaxTokens_ZeroRole_UsesDefault()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        TempArg: Record "MCP Chat Argument ori" temporary;
    begin
        TempArg.Init();
        Assert.AreEqual(4096, ProviderBase.GetMaxTokens(TempArg, 4096), 'Should use default');
    end;
}
