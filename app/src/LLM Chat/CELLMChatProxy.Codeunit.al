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
        ChatUtils: Codeunit "CE MCP Chat Utils ori";

    [NonDebuggable]
    internal procedure SendChatMessage(PayloadJson: Text): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        ApiClient: Codeunit "CE LLM API Client ori";
        PayloadObject: JsonObject;
        Messages: JsonArray;
        OpenAITools: JsonArray;
        Model: Text;
        SystemPrompt: Text;
        ApiKey: Text;
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

        exit(CallLLMOnce(ApiClient, ProviderSetup, Messages, OpenAITools, Model, ApiKey));
    end;

    [NonDebuggable]
    internal procedure ContinueWithToolResults(ConversationState: Text; ToolResultsJson: Text): Text
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        ApiClient: Codeunit "CE LLM API Client ori";
        StateObject: JsonObject;
        Messages: JsonArray;
        OpenAITools: JsonArray;
        MessagesToken: JsonToken;
        Model: Text;
        ApiKey: Text;
    begin
        if not LLMChatSetup.ResolveProvider(ProviderSetup) then
            exit(BuildErrorResponse('No LLM provider configured.'));

        ApiKey := ProviderSetup.GetApiKey();
        if ApiKey = '' then
            exit(BuildErrorResponse('API key not configured.'));

        if not StateObject.ReadFrom(ConversationState) then
            exit(BuildErrorResponse('Invalid conversation state.'));

        Model := GetTextProperty(StateObject, 'model');
        if StateObject.Get('messages', MessagesToken) then
            Messages := MessagesToken.AsArray();
        BuildToolDefinitions(OpenAITools);

        AppendToolResultMessages(Messages, ToolResultsJson);

        exit(CallLLMOnce(ApiClient, ProviderSetup, Messages, OpenAITools, Model, ApiKey));
    end;

    [NonDebuggable]
    local procedure CallLLMOnce(var ApiClient: Codeunit "CE LLM API Client ori"; var ProviderSetup: Record "CE LLM Provider Setup ori"; var Messages: JsonArray; OpenAITools: JsonArray; Model: Text; ApiKey: Text): Text
    var
        Response: JsonObject;
        RequestBody: JsonObject;
        ChoicesToken: JsonToken;
        FirstChoice: JsonToken;
        MessageObject: JsonObject;
        MessageToken: JsonToken;
        ToolCallsToken: JsonToken;
        AssistantMessage: JsonObject;
        UsageObject: JsonObject;
        UsageToken: JsonToken;
        Reply: Text;
        FinishReason: Text;
    begin
        ChatUtils.CompactOlderToolResults(Messages, 5, 500);
        ChatUtils.TrimMessageHistory(Messages, 80000);

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
        if FinishReason = 'tool_calls' then begin
            if not MessageObject.Get('tool_calls', ToolCallsToken) then
                exit(BuildErrorResponse('Model signaled tool_calls but none present.'));
            exit(BuildToolCallsResponse(ToolCallsToken.AsArray(), Messages, Model, UsageObject));
        end;

        Reply := GetTextProperty(MessageObject, 'content');
        exit(BuildSuccessResponse(Reply, UsageObject));
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

    local procedure AppendToolResultMessages(var Messages: JsonArray; ToolResultsJson: Text)
    var
        ResultsArray: JsonArray;
        ResultToken: JsonToken;
        ResultObj: JsonObject;
        ToolMsg: JsonObject;
        ResultText: Text;
    begin
        if not ResultsArray.ReadFrom(ToolResultsJson) then
            exit;
        foreach ResultToken in ResultsArray do begin
            if not ResultToken.IsObject() then
                continue;
            ResultObj := ResultToken.AsObject();
            Clear(ToolMsg);
            ToolMsg.Add('role', 'tool');
            ToolMsg.Add('tool_call_id', GetTextProperty(ResultObj, 'id'));
            ResultText := ChatUtils.TruncateContent(GetTextProperty(ResultObj, 'result'), 0);
            ToolMsg.Add('content', ResultText);
            Messages.Add(ToolMsg);
        end;
    end;

    local procedure BuildToolCallsResponse(ToolCallsArray: JsonArray; Messages: JsonArray; Model: Text; Usage: JsonObject) ResponseJson: Text
    var
        ResponseObject: JsonObject;
        NormalizedCalls: JsonArray;
        CallToken: JsonToken;
        CallObject: JsonObject;
        FunctionToken: JsonToken;
        FunctionObject: JsonObject;
        NormalizedCall: JsonObject;
        InputObject: JsonObject;
        StateObject: JsonObject;
        ArgumentsText: Text;
        ToolName: Text;
        StateText: Text;
    begin
        foreach CallToken in ToolCallsArray do begin
            if not CallToken.IsObject() then
                continue;
            CallObject := CallToken.AsObject();
            if not CallObject.Get('function', FunctionToken) then
                continue;
            FunctionObject := FunctionToken.AsObject();
            ToolName := GetTextProperty(FunctionObject, 'name');
            ArgumentsText := GetTextProperty(FunctionObject, 'arguments');

            Clear(NormalizedCall);
            NormalizedCall.Add('id', GetTextProperty(CallObject, 'id'));
            NormalizedCall.Add('name', ToolName);
            if (ArgumentsText <> '') and InputObject.ReadFrom(ArgumentsText) then begin
                InjectTableFormat(ToolName, InputObject);
                NormalizedCall.Add('arguments', InputObject);
            end;
            NormalizedCalls.Add(NormalizedCall);
        end;

        StateObject.Add('messages', Messages);
        StateObject.Add('model', Model);
        StateObject.WriteTo(StateText);

        ResponseObject.Add('type', 'tool_calls');
        ResponseObject.Add('toolCalls', NormalizedCalls);
        ResponseObject.Add('conversationState', StateText);
        if Usage.Keys().Count() > 0 then
            ResponseObject.Add('usage', Usage);
        ResponseObject.WriteTo(ResponseJson);
    end;

    local procedure BuildSuccessResponse(Reply: Text; Usage: JsonObject) ResponseJson: Text
    var
        ResponseObject: JsonObject;
    begin
        ResponseObject.Add('type', 'reply');
        ResponseObject.Add('reply', Reply);
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

    local procedure InjectTableFormat(ToolName: Text; var Arguments: JsonObject)
    var
        FormatToken: JsonToken;
    begin
        if not (ToolName in ['get_records', 'get_record_ids', 'get_totals', 'find_entries',
                             'invoke_message_type', 'get_fields', 'search_tables']) then
            exit;
        if Arguments.Get('format', FormatToken) then
            exit;
        Arguments.Add('format', 'table');
    end;
}
