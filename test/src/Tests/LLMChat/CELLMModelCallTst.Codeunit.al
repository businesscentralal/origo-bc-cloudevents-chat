namespace Origo.APP.CloudEvents.LLM;

using System.TestLibraries.Utilities;

/// <summary>
/// Tests for the LLM.Model.Call and LLM.Model.List server-side calls, covering the
/// plain completion, API errors, model listing, and the AI decision/summary patterns.
/// The LLM HTTP call is mocked via the LLM AI Handler, so no network access or API key is required.
/// </summary>
codeunit 95905 "CE LLM Model Call Tst ori"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit "Library Assert";
        LLMAIHandler: Codeunit "CE LLM AI Handler ori";

    [Test]
    procedure Complete_ReturnsMockedText()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        ResultText: Text;
    begin
        // [SCENARIO] A successful completion returns the assistant text from the mocked response.

        // [GIVEN] A mocked successful LLM response
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetResponse('{"choices":[{"message":{"role":"assistant","content":"connection ok"},"finish_reason":"stop"}]}');

        // [WHEN] A completion is requested
        ResultText := ApiClient.Complete('test-model', '', 'ping', 100);

        // [THEN] The assistant text is returned
        Assert.AreEqual('connection ok', ResultText, 'Complete should return the mocked assistant text.');

        UnbindSubscription(LLMAIHandler);
    end;

    [Test]
    procedure Complete_ApiError_Raised()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        ResultText: Text;
    begin
        // [SCENARIO] A failed LLM call surfaces as an error.

        // [GIVEN] The next call is configured to fail
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetErrorResponse('Could not reach the LLM API.');

        // [WHEN] A completion is requested
        asserterror ResultText := ApiClient.Complete('test-model', '', 'ping', 100);

        // [THEN] The error is raised
        Assert.ExpectedError('Could not reach the LLM API.');

        UnbindSubscription(LLMAIHandler);
    end;

    [Test]
    procedure AiDecisionStep_ReturnsApprove()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        DecisionText: Text;
    begin
        // [SCENARIO] An AI decision step returns APPROVE.

        // [GIVEN] The model is mocked to approve
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetResponse('{"choices":[{"message":{"role":"assistant","content":"APPROVE"},"finish_reason":"stop"}]}');

        // [WHEN] The decision prompt is sent
        DecisionText := ApiClient.Complete('test-model', 'Reply APPROVE or REVIEW.', 'Customer 10000 credit check. Auto-post?', 50);

        // [THEN] The decision is APPROVE
        Assert.AreEqual('APPROVE', DecisionText, 'The AI decision step should return the APPROVE token.');

        UnbindSubscription(LLMAIHandler);
    end;

    [Test]
    procedure AiSummaryStep_ReturnsSentence()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        SummaryText: Text;
        ExpectedSummary: Text;
    begin
        // [SCENARIO] An AI summary step returns a human-readable sentence.

        // [GIVEN] The model is mocked to return a confirmation sentence
        ExpectedSummary := 'Sales order 101028 for customer 10000 has been posted.';
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetResponse('{"choices":[{"message":{"role":"assistant","content":"' + ExpectedSummary + '"},"finish_reason":"stop"}]}');

        // [WHEN] The summary prompt is sent
        SummaryText := ApiClient.Complete('test-model', '', 'Confirm the posted order in one sentence.', 200);

        // [THEN] The confirmation sentence is returned
        Assert.AreEqual(ExpectedSummary, SummaryText, 'The AI summary step should return the confirmation sentence.');

        UnbindSubscription(LLMAIHandler);
    end;

    [Test]
    procedure SendChatCompletion_ParsesResponseObject()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        RequestBody: JsonObject;
        Messages: JsonArray;
        UserMessage: JsonObject;
        Response: JsonObject;
    begin
        // [SCENARIO] SendChatCompletion returns a parsed response object whose text can be extracted.

        // [GIVEN] A mocked response and a well-formed request body
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetResponse('{"choices":[{"message":{"role":"assistant","content":"parsed"},"finish_reason":"stop"}]}');

        UserMessage.Add('role', 'user');
        UserMessage.Add('content', 'hi');
        Messages.Add(UserMessage);
        RequestBody.Add('model', 'test-model');
        RequestBody.Add('max_tokens', 100);
        RequestBody.Add('messages', Messages);

        // [WHEN] The request is sent and the text extracted
        Response := ApiClient.SendChatCompletion(RequestBody);

        // [THEN] The extracted text matches the mocked response
        Assert.AreEqual('parsed', ApiClient.ExtractText(Response), 'ExtractText should return the mocked text from the parsed response.');

        UnbindSubscription(LLMAIHandler);
    end;

    [Test]
    procedure ListModels_ReturnsModelArray()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        Models: JsonArray;
        ModelToken: JsonToken;
        IdToken: JsonToken;
    begin
        // [SCENARIO] LLM.Model.List returns the model objects from the Models API payload.

        // [GIVEN] A mocked models response
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetResponse('{"data":[{"id":"qwen3:8b","object":"model"},{"id":"qwen2.5:14b","object":"model"}]}');

        // [WHEN] The models are listed
        Models := ApiClient.ListModels();

        // [THEN] Both models are returned in order
        Assert.AreEqual(2, Models.Count(), 'ListModels should return every model in the data array.');
        Models.Get(0, ModelToken);
        ModelToken.AsObject().Get('id', IdToken);
        Assert.AreEqual('qwen3:8b', IdToken.AsValue().AsText(), 'The first model id should match the mocked response.');

        UnbindSubscription(LLMAIHandler);
    end;

    [Test]
    procedure ListModels_ApiError_Raised()
    var
        ApiClient: Codeunit "CE LLM API Client ori";
    begin
        // [SCENARIO] A failed models call surfaces as an error.

        // [GIVEN] The next call is configured to fail
        BindSubscription(LLMAIHandler);
        LLMAIHandler.SetErrorResponse('Could not reach the LLM API.');

        // [WHEN] The models are listed
        asserterror ApiClient.ListModels();

        // [THEN] The error is raised
        Assert.ExpectedError('Could not reach the LLM API.');

        UnbindSubscription(LLMAIHandler);
    end;
}
