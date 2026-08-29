namespace Origo.APP.CloudEvents.Chat;

using System.TestLibraries.Utilities;

/// <summary>
/// Tests for provider-specific response format parsing and error handling.
/// Uses direct JSON construction to verify parsing without HTTP calls.
/// </summary>
codeunit 95908 "CE Chat Response Parse Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";

    [Test]
    procedure Complete_MockedResponse_ReturnsText()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
    begin
        // [GIVEN] A mocked chat completion response
        ApiClient.SetMockResponse('{"choices":[{"message":{"content":"extracted data"},"finish_reason":"stop"}]}');

        // [WHEN/THEN]
        Assert.AreEqual('extracted data', ApiClient.Complete('model', 'system', 'prompt', 100),
            'Should return assistant content from mocked response.');
    end;

    [Test]
    procedure Complete_MockError_RaisesError()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
    begin
        ApiClient.SetMockError('Service unavailable');
        asserterror ApiClient.Complete('model', '', 'prompt', 100);
        Assert.ExpectedError('Service unavailable');
    end;

    [Test]
    procedure Complete_WithSystemPrompt_Succeeds()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
    begin
        // [GIVEN] A response with system prompt
        ApiClient.SetMockResponse('{"choices":[{"message":{"content":"ok"},"finish_reason":"stop"}]}');

        // [WHEN/THEN] System prompt doesn't break the call
        Assert.AreEqual('ok', ApiClient.Complete('model', 'You are an assistant', 'Hello', 100),
            'System prompt should be accepted.');
    end;

    [Test]
    procedure ExtractText_ContentIsNull_ReturnsEmpty()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        Response: JsonObject;
    begin
        // [GIVEN] Response where content is null
        Response.ReadFrom('{"choices":[{"message":{"content":null},"finish_reason":"stop"}]}');

        // [WHEN/THEN]
        Assert.AreEqual('', ApiClient.ExtractText(Response), 'Null content should return empty.');
    end;

    [Test]
    procedure ExtractText_ContentArray_ReturnsEmpty()
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        Response: JsonObject;
    begin
        // [GIVEN] Response where content is an array (multi-modal response)
        Response.ReadFrom('{"choices":[{"message":{"content":[{"type":"text","text":"hello"}]},"finish_reason":"stop"}]}');

        // [WHEN/THEN] ExtractText only handles string content
        Assert.AreEqual('', ApiClient.ExtractText(Response), 'Array content should return empty (not a value).');
    end;

    [Test]
    procedure ParseTokenUsage_StandardFormat()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        InTokens: Integer;
        OutTokens: Integer;
    begin
        // [GIVEN] Standard OpenAI usage format
        ProviderBase.ParseTokenUsage(
            '{"usage":{"prompt_tokens":150,"completion_tokens":42}}',
            InTokens, OutTokens);

        // [THEN]
        Assert.AreEqual(150, InTokens, 'Input tokens should be 150.');
        Assert.AreEqual(42, OutTokens, 'Output tokens should be 42.');
    end;

    [Test]
    procedure ParseTokenUsage_MissingUsage_ReturnsZero()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        InTokens: Integer;
        OutTokens: Integer;
    begin
        ProviderBase.ParseTokenUsage('{"model":"test"}', InTokens, OutTokens);
        Assert.AreEqual(0, InTokens, 'Missing usage should return 0.');
        Assert.AreEqual(0, OutTokens, 'Missing usage should return 0.');
    end;

    [Test]
    procedure ParseTokenUsage_InvalidJson_ReturnsZero()
    var
        ProviderBase: Codeunit "CE Chat Provider Base ori";
        InTokens: Integer;
        OutTokens: Integer;
    begin
        ProviderBase.ParseTokenUsage('not json', InTokens, OutTokens);
        Assert.AreEqual(0, InTokens, 'Invalid JSON should return 0.');
        Assert.AreEqual(0, OutTokens, 'Invalid JSON should return 0.');
    end;
}
