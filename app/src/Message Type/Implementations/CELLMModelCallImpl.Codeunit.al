namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Implementation of the LLM.Model.Call message type.
/// Sends a prompt to the LLM via OpenAI-compatible Chat Completions API using an
/// explicitly named model and returns the assistant text. When the request supplies
/// a "tools" array, the named Cloud Events message types are exposed to the model
/// and executed via the dispatcher in a tool loop.
/// </summary>
codeunit 10035491 "CE LLM Model Call Impl ori" implements "Cloud Event Msg Interface ori"
{
    Access = Internal;

    /// <summary>
    /// Determines whether this message type is enabled.
    /// </summary>
    internal procedure IsEnabled(): Boolean
    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
    begin
        exit(LLMChatSetup.HasServiceGate());
    end;

    /// <summary>
    /// Returns the table ID used to filter records for this message type.
    /// </summary>
    internal procedure GetFilterTableNo(): Integer
    begin
        exit(0);
    end;

    /// <summary>
    /// Returns a human-readable description of this message type.
    /// </summary>
    internal procedure GetDescription() Description: Text[250]
    var
        DescriptionLbl: Label 'Send a prompt to a named LLM model and return the response.', Comment = 'is-IS=Senda kvaðningu til tiltekins LLM líkans og fá svarið.';
    begin
        exit(DescriptionLbl);
    end;

    /// <summary>
    /// Returns the message direction for this message type.
    /// </summary>
    internal procedure GetMessageDirection(): Enum "Cloud Event Msg Direction ori"
    begin
        exit(Enum::"Cloud Event Msg Direction ori"::Outbound);
    end;

    /// <summary>
    /// Returns Markdown help documentation for this message type.
    /// </summary>
    internal procedure GetMessageHelpAsMarkdownDocument(var Argument: Record "CE Message Argument ori")
    var
        HelpCodeunit: Codeunit "CE LLM Model Call Help ori";
    begin
        Argument.SetResponseMarkdown(HelpCodeunit.GetHelpText());
    end;

    /// <summary>
    /// Parses the JSON request, calls the named LLM model, and returns the assistant text.
    /// When "tools" are supplied, runs a tool loop over the named Cloud Events message types.
    /// </summary>
    [NonDebuggable]
    internal procedure ExecuteCloudEventTask(var Argument: Record "CE Message Argument ori")
    var
        ApiClient: Codeunit "CE LLM API Client ori";
        ToolRunner: Codeunit "CE LLM Tool Runner ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        RequestJson: JsonObject;
        ResponseJson: JsonObject;
        ToolsToken: JsonToken;
        Model: Text;
        SystemPrompt: Text;
        UserPrompt: Text;
        MaxTokens: Integer;
        MaxToolIterations: Integer;
        AnswerText: Text;
        HasTools: Boolean;
    begin
        Argument.AssertVersion1();
        Argument.AssertIsLicensed();
        if not LLMChatSetup.AssertServiceGate(Argument) then
            exit;

        RequestJson := Argument.GetRequestJson();

        Model := GetTextValue(RequestJson, 'model');
        SystemPrompt := GetTextValue(RequestJson, 'system');
        UserPrompt := GetTextValue(RequestJson, 'prompt');
        MaxTokens := GetIntValue(RequestJson, 'maxTokens');
        MaxToolIterations := GetIntValue(RequestJson, 'maxToolIterations');
        if RequestJson.Get('tools', ToolsToken) then
            HasTools := ToolsToken.IsArray() and (ToolsToken.AsArray().Count() > 0);

        if Model = '' then begin
            Argument.RespondWithError(MissingModelErr);
            exit;
        end;

        if UserPrompt = '' then begin
            Argument.RespondWithError(MissingPromptErr);
            exit;
        end;

        if HasTools then
            AnswerText := ToolRunner.RunWithTools(Model, SystemPrompt, UserPrompt, ResolveMaxTokens(MaxTokens), ToolsToken.AsArray(), MaxToolIterations)
        else
            AnswerText := ApiClient.Complete(Model, SystemPrompt, UserPrompt, MaxTokens);

        ResponseJson.Add('status', 'Success');
        ResponseJson.Add('model', Model);
        ResponseJson.Add('text', AnswerText);
        Argument.SetResponseJson(ResponseJson);
        Argument."Content Type" := Argument.GetContentTypeJson();
    end;

    local procedure ResolveMaxTokens(MaxTokens: Integer): Integer
    begin
        if MaxTokens > 0 then
            exit(MaxTokens);
        exit(4096);
    end;

    local procedure GetTextValue(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
        exit('');
    end;

    local procedure GetIntValue(Source: JsonObject; PropertyName: Text): Integer
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsInteger());
        exit(0);
    end;

    var
        MissingModelErr: Label 'A model is required. Provide a JSON object with a "model" property. Call LLM.Model.List to get the available model ids.', Comment = 'is-IS=Líkan er nauðsynlegt. Sendu JSON hlut með eigindinni "model". Kallaðu á LLM.Model.List til að sjá tiltæk líkön.';
        MissingPromptErr: Label 'A prompt is required. Provide a "prompt" property in the request.', Comment = 'is-IS=Kvaðning er nauðsynleg. Sendu eigindina "prompt" í beiðninni.';
}
