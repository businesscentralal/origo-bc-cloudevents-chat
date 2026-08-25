namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;
using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the LLM-specific "LLM Model" field added by the
/// "LLM MCP Chat Role" tableextension on the base "MCP Chat Role" table.
/// </summary>
codeunit 95902 "CE LLM Chat Role Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        IsInitialized: Boolean;

    local procedure Initialize()
    begin
        if IsInitialized then
            exit;

        IsInitialized := true;
    end;

    [Test]
    procedure ValidateModel_EmptyValue_NoError()
    var
        LLMChatRole: Record "MCP Chat Role ori";
    begin
        // [SCENARIO] Validating LLM Model with empty value does not produce an error.
        Initialize();

        // [GIVEN] A new Chat Role record
        LLMChatRole.Init();
        LLMChatRole.Code := CopyStr('X-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LLMChatRole.Code));
        LLMChatRole.Insert(true);

        // [WHEN] LLM Model is validated with empty string
        LLMChatRole.Validate("CE LLM Model ori", '');

        // [THEN] No error is thrown (empty exits early)
        Assert.AreEqual('', LLMChatRole."CE LLM Model ori", 'LLM Model should be empty after validating with empty string.');
    end;

    [Test]
    procedure ValidateModel_ApiUnreachable_AllowsAnyValue()
    var
        LLMChatRole: Record "MCP Chat Role ori";
    begin
        // [SCENARIO] When the models API is unreachable, any model value is accepted.
        Initialize();

        // [GIVEN] A new Chat Role record
        LLMChatRole.Init();
        LLMChatRole.Code := CopyStr('X-' + Format(CreateGuid(), 0, 4), 1, MaxStrLen(LLMChatRole.Code));

        // [WHEN] LLM Model is validated with a model name (API cannot be reached in test)
        LLMChatRole.Validate("CE LLM Model ori", 'qwen3:8b');

        // [THEN] No error is thrown because the API check exits gracefully
        Assert.AreEqual('qwen3:8b', LLMChatRole."CE LLM Model ori", 'LLM Model should accept any value when API is unreachable.');
    end;
}
