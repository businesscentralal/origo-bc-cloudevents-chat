namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Runs the LLM agentic tool loop. Calls the OpenAI-compatible Chat Completions API,
/// dispatches tool_calls via the Core MCP Tool Server, feeds results back,
/// and repeats until the model produces a final answer.
/// </summary>
codeunit 10035487 "CE LLM Chat Proxy ori"
{
    Access = Internal;

    var
        ToolServer: Codeunit "CE MCP Tool Server";

    [NonDebuggable]
    internal procedure SendChatMessage(PayloadJson: Text): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        ApiClient: Codeunit "CE LLM API Client ori";
        PayloadObject: JsonObject;
        Messages: JsonArray;
        OpenAITools: JsonArray;
        ToolTrace: JsonArray;
        Response: JsonObject;
        UsageObject: JsonObject;
        UsageToken: JsonToken;
        RequestBody: JsonObject;
        ChoicesToken: JsonToken;
        FirstChoice: JsonToken;
        MessageObject: JsonObject;
        MessageToken: JsonToken;
        ToolCallsToken: JsonToken;
        AssistantMessage: JsonObject;
        ToolResults: JsonArray;
        Model: Text;
        SystemPrompt: Text;
        ApiKey: Text;
        Reply: Text;
        FinishReason: Text;
        Iteration: Integer;
        MaxIterations: Integer;
    begin
        if not PayloadObject.ReadFrom(PayloadJson) then
            exit(BuildErrorResponse('Invalid payload JSON.'));

        if not LLMChatSetup.ResolveProvider(ProviderSetup) then
            exit(BuildErrorResponse('No LLM provider configured.'));

        ApiKey := ProviderSetup.GetApiKey();
        if ApiKey = '' then
            exit(BuildErrorResponse('API key not configured.'));

        Model := GetTextProperty(PayloadObject, 'model');
        if Model = '' then
            Model := ProviderSetup.ResolveModel('');

        SystemPrompt := BuildSystemPrompt(PayloadObject);
        ParseMessages(PayloadObject, Messages);

        if SystemPrompt <> '' then
            AddSystemMessage(Messages, SystemPrompt);

        BuildToolDefinitions(OpenAITools);

        MaxIterations := 25;
        for Iteration := 1 to MaxIterations do begin
            Clear(RequestBody);
            RequestBody.Add('model', Model);
            RequestBody.Add('max_completion_tokens', ProviderSetup.GetMaxTokens());
            RequestBody.Add('messages', Messages);
            if OpenAITools.Count() > 0 then
                RequestBody.Add('tools', OpenAITools);

            if not TrySendToLLM(ApiClient, ProviderSetup, RequestBody, ApiKey, Response) then begin
                ApiClient.LogLastRequest();
                exit(BuildErrorResponse(GetLastErrorText()));
            end;
            ApiClient.LogLastRequest();

            if not Response.Get('choices', ChoicesToken) then
                exit(BuildErrorResponse('Empty response from AI model.'));
            if ChoicesToken.AsArray().Count() = 0 then
                exit(BuildErrorResponse('Empty response from AI model.'));

            ChoicesToken.AsArray().Get(0, FirstChoice);
            FirstChoice.AsObject().Get('message', MessageToken);
            MessageObject := MessageToken.AsObject();

            Clear(AssistantMessage);
            AssistantMessage.Add('role', 'assistant');
            CopyMessageContent(MessageObject, AssistantMessage);
            Messages.Add(AssistantMessage);

            if Response.Get('usage', UsageToken) then
                if UsageToken.IsObject() then
                    UsageObject := UsageToken.AsObject();

            FinishReason := GetTextProperty(FirstChoice.AsObject(), 'finish_reason');
            if FinishReason <> 'tool_calls' then begin
                Reply := GetTextProperty(MessageObject, 'content');
                exit(BuildSuccessResponse(Reply, ToolTrace, UsageObject));
            end;

            if not MessageObject.Get('tool_calls', ToolCallsToken) then
                exit(BuildErrorResponse('Model signaled tool_calls but none present.'));

            Clear(ToolResults);
            ExecuteToolCalls(ToolCallsToken.AsArray(), ToolResults, ToolTrace);

            AddToolResultMessages(Messages, ToolResults);
        end;

        Reply := GetTextProperty(MessageObject, 'content');
        exit(BuildSuccessResponse(Reply, ToolTrace, UsageObject));
    end;

    local procedure AddSystemMessage(var Messages: JsonArray; SystemPrompt: Text)
    var
        SystemMsg: JsonObject;
    begin
        SystemMsg.Add('role', 'system');
        SystemMsg.Add('content', SystemPrompt);
        Messages.Add(SystemMsg);
    end;

    local procedure CopyMessageContent(Source: JsonObject; var Target: JsonObject)
    var
        ContentToken: JsonToken;
        ToolCallsToken: JsonToken;
    begin
        if Source.Get('content', ContentToken) then
            Target.Add('content', ContentToken)
        else
            Target.Add('content', '');
        if Source.Get('tool_calls', ToolCallsToken) then
            Target.Add('tool_calls', ToolCallsToken);
    end;

    local procedure AddToolResultMessages(var Messages: JsonArray; ToolResults: JsonArray)
    var
        ResultToken: JsonToken;
    begin
        foreach ResultToken in ToolResults do
            Messages.Add(ResultToken);
    end;

    local procedure BuildSystemPrompt(PayloadObject: JsonObject) SystemPrompt: Text
    var
        RecordContext: Text;
        UserPrompt: Text;
        UserSkill: Text;
    begin
        RecordContext := GetTextProperty(PayloadObject, 'recordContext');
        SystemPrompt := ToolServer.Bootstrap(RecordContext);

        UserPrompt := GetTextProperty(PayloadObject, 'systemPrompt');
        if UserPrompt <> '' then
            SystemPrompt += '\n\nUSER INSTRUCTIONS:\n' + UserPrompt;

        UserSkill := GetTextProperty(PayloadObject, 'skill');
        if UserSkill <> '' then
            SystemPrompt += '\n\nSKILL REFERENCE:\n' + UserSkill;
    end;

    local procedure BuildToolDefinitions(var OpenAITools: JsonArray)
    var
        ServerTools: JsonArray;
        ToolToken: JsonToken;
        ToolObject: JsonObject;
        OpenAITool: JsonObject;
        FunctionDef: JsonObject;
        SchemaToken: JsonToken;
    begin
        ToolServer.ListTools(ServerTools);
        foreach ToolToken in ServerTools do begin
            ToolObject := ToolToken.AsObject();
            Clear(OpenAITool);
            Clear(FunctionDef);
            FunctionDef.Add('name', GetTextProperty(ToolObject, 'name'));
            FunctionDef.Add('description', GetTextProperty(ToolObject, 'description'));
            if ToolObject.Get('inputSchema', SchemaToken) then
                FunctionDef.Add('parameters', SchemaToken);
            OpenAITool.Add('type', 'function');
            OpenAITool.Add('function', FunctionDef);
            OpenAITools.Add(OpenAITool);
        end;
    end;

    [TryFunction]
    [NonDebuggable]
    local procedure TrySendToLLM(var ApiClient: Codeunit "CE LLM API Client ori"; var ProviderSetup: Record "CE LLM Provider Setup ori"; RequestBody: JsonObject; ApiKey: Text; var Response: JsonObject)
    begin
        Response := ApiClient.SendForProvider(ProviderSetup, RequestBody, ApiKey);
    end;

    local procedure ParseMessages(PayloadObject: JsonObject; var Messages: JsonArray)
    var
        MessagesToken: JsonToken;
    begin
        if PayloadObject.Get('messages', MessagesToken) then
            if MessagesToken.IsArray() then
                Messages := MessagesToken.AsArray();
    end;

    local procedure ExecuteToolCalls(ToolCallsArray: JsonArray; var ToolResults: JsonArray; var ToolTrace: JsonArray)
    var
        CallToken: JsonToken;
        CallObject: JsonObject;
    begin
        foreach CallToken in ToolCallsArray do begin
            if not CallToken.IsObject() then
                continue;
            CallObject := CallToken.AsObject();
            ToolResults.Add(ExecuteSingleTool(CallObject, ToolTrace));
        end;
    end;

    local procedure ExecuteSingleTool(CallObject: JsonObject; var ToolTrace: JsonArray) ToolResult: JsonObject
    var
        TraceEntry: JsonObject;
        FunctionToken: JsonToken;
        FunctionObject: JsonObject;
        InputObject: JsonObject;
        ToolCallId: Text;
        ToolName: Text;
        ArgumentsText: Text;
        ResultText: Text;
        IsError: Boolean;
        StartTime: DateTime;
        DurationMs: Integer;
    begin
        ToolCallId := GetTextProperty(CallObject, 'id');
        if not CallObject.Get('function', FunctionToken) then
            exit;
        FunctionObject := FunctionToken.AsObject();
        ToolName := GetTextProperty(FunctionObject, 'name');
        ArgumentsText := GetTextProperty(FunctionObject, 'arguments');

        if ArgumentsText <> '' then
            if not InputObject.ReadFrom(ArgumentsText) then
                Clear(InputObject);

        StartTime := CurrentDateTime();
        ToolServer.CallTool(ToolName, InputObject, ResultText, IsError);
        DurationMs := CurrentDateTime() - StartTime;

        ToolResult.Add('role', 'tool');
        ToolResult.Add('tool_call_id', ToolCallId);
        ToolResult.Add('content', ResultText);

        TraceEntry.Add('tool', ToolName);
        if IsError then begin
            TraceEntry.Add('status', 'error');
            TraceEntry.Add('error', CopyStr(ResultText, 1, 500));
        end else
            TraceEntry.Add('status', 'success');
        TraceEntry.Add('durationMs', DurationMs);
        ToolTrace.Add(TraceEntry);
    end;

    local procedure BuildSuccessResponse(Reply: Text; ToolTrace: JsonArray; Usage: JsonObject) ResponseJson: Text
    var
        ResponseObject: JsonObject;
    begin
        ResponseObject.Add('reply', Reply);
        if ToolTrace.Count() > 0 then
            ResponseObject.Add('toolTrace', ToolTrace);
        if Usage.Keys().Count() > 0 then
            ResponseObject.Add('usage', Usage);
        ResponseObject.WriteTo(ResponseJson);
    end;

    local procedure BuildErrorResponse(ErrorMessage: Text) ResponseJson: Text
    var
        ErrorObject: JsonObject;
    begin
        ErrorObject.Add('error', ErrorMessage);
        ErrorObject.WriteTo(ResponseJson);
    end;

    local procedure GetTextProperty(Source: JsonObject; PropertyName: Text): Text
    var
        Token: JsonToken;
    begin
        if Source.Get(PropertyName, Token) then
            if Token.IsValue() then
                exit(Token.AsValue().AsText());
    end;
}
