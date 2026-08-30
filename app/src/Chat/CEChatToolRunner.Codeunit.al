namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

/// <summary>
/// Runs an LLM tool loop where selected Cloud Events message types are exposed to
/// the model as tools. Delegates tool execution to the Core MCP Tool Server. Server-side only.
/// </summary>
codeunit 10035490 "CE Chat Tool Runner ori"
{
    Access = Internal;

    var
        ToolServer: Codeunit "CE MCP Tool Server";
        ToolNameMap: Dictionary of [Text, Integer];
        UnknownToolErr: Label 'Unknown tool: %1', Comment = '%1 = tool name, is-IS=Óþekkt tól: %1';

    /// <summary>
    /// Runs a tool-enabled completion. ToolNames holds Cloud Events message type names
    /// to expose as LLM tools. Execution is delegated to the Core MCP Tool Server.
    /// </summary>
    [NonDebuggable]
    procedure RunWithTools(Model: Text; SystemPrompt: Text; UserPrompt: Text; MaxTokens: Integer; ToolNames: JsonArray; MaxIterations: Integer): Text
    var
        ApiClient: Codeunit "CE Chat API Client ori";
        OpenAITools: JsonArray;
        Messages: JsonArray;
        SystemMessage: JsonObject;
        UserMessage: JsonObject;
        AssistantMessage: JsonObject;
        RequestBody: JsonObject;
        Response: JsonObject;
        ChoicesToken: JsonToken;
        FirstChoice: JsonToken;
        MessageToken: JsonToken;
        MessageObject: JsonObject;
        ToolCallsToken: JsonToken;
        FinishReason: Text;
        Iteration: Integer;
    begin
        BuildTools(ToolNames, OpenAITools);

        if SystemPrompt <> '' then begin
            SystemMessage.Add('role', 'system');
            SystemMessage.Add('content', SystemPrompt);
            Messages.Add(SystemMessage);
        end;

        UserMessage.Add('role', 'user');
        UserMessage.Add('content', UserPrompt);
        Messages.Add(UserMessage);

        if MaxIterations <= 0 then
            MaxIterations := 8;

        for Iteration := 1 to MaxIterations do begin
            Clear(RequestBody);
            RequestBody.Add('model', Model);
            RequestBody.Add('max_completion_tokens', MaxTokens);
            RequestBody.Add('messages', Messages);
            if OpenAITools.Count() > 0 then
                RequestBody.Add('tools', OpenAITools);

            Response := ApiClient.SendChatCompletion(RequestBody);
            ApiClient.LogLastRequest();

            if not Response.Get('choices', ChoicesToken) then
                exit('');
            if ChoicesToken.AsArray().Count() = 0 then
                exit('');

            ChoicesToken.AsArray().Get(0, FirstChoice);
            FirstChoice.AsObject().Get('message', MessageToken);
            MessageObject := MessageToken.AsObject();

            Clear(AssistantMessage);
            AssistantMessage.Add('role', 'assistant');
            CopyMessageContent(MessageObject, AssistantMessage);
            Messages.Add(AssistantMessage);

            FinishReason := GetTextValue(FirstChoice.AsObject(), 'finish_reason');
            if FinishReason <> 'tool_calls' then
                exit(ApiClient.ExtractText(Response));

            if not MessageObject.Get('tool_calls', ToolCallsToken) then
                exit('');

            RunToolCalls(ToolCallsToken.AsArray(), Messages);
        end;

        exit(ApiClient.ExtractText(Response));
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

    local procedure BuildTools(ToolNames: JsonArray; var OpenAITools: JsonArray)
    var
        ServerTools: JsonArray;
        ToolToken: JsonToken;
        ToolObject: JsonObject;
        OpenAITool: JsonObject;
        FunctionDef: JsonObject;
        SchemaToken: JsonToken;
    begin
        Clear(ToolNameMap);
        ToolServer.BuildDynamicToolDefs(ToolNames, ServerTools, ToolNameMap);

        foreach ToolToken in ServerTools do begin
            ToolObject := ToolToken.AsObject();
            Clear(OpenAITool);
            Clear(FunctionDef);
            FunctionDef.Add('name', GetTextValue(ToolObject, 'name'));
            FunctionDef.Add('description', GetTextValue(ToolObject, 'description'));
            if ToolObject.Get('inputSchema', SchemaToken) then
                FunctionDef.Add('parameters', SchemaToken);
            OpenAITool.Add('type', 'function');
            OpenAITool.Add('function', FunctionDef);
            OpenAITools.Add(OpenAITool);
        end;
    end;

    local procedure RunToolCalls(ToolCallsArray: JsonArray; var Messages: JsonArray)
    var
        CallToken: JsonToken;
        CallObject: JsonObject;
        FunctionToken: JsonToken;
        FunctionObject: JsonObject;
        Arguments: JsonObject;
        ToolCallId: Text;
        ToolName: Text;
        ArgumentsText: Text;
        MsgTypeName: Text;
        ResultText: Text;
        MessageOrdinal: Integer;
        IsError: Boolean;
        ToolResultMsg: JsonObject;
    begin
        foreach CallToken in ToolCallsArray do begin
            CallObject := CallToken.AsObject();
            ToolCallId := GetTextValue(CallObject, 'id');
            if not CallObject.Get('function', FunctionToken) then
                continue;
            FunctionObject := FunctionToken.AsObject();
            ToolName := GetTextValue(FunctionObject, 'name');
            ArgumentsText := GetTextValue(FunctionObject, 'arguments');

            if ToolNameMap.Get(ToolName, MessageOrdinal) then begin
                MsgTypeName := Format("Cloud Event Message Type ori".FromInteger(MessageOrdinal));
                Clear(Arguments);
                Arguments.Add('type', MsgTypeName);
                if ArgumentsText <> '' then
                    Arguments.Add('data', ArgumentsText);
                ToolServer.CallTool('invoke_message_type', Arguments, ResultText, IsError);
            end else begin
                ResultText := StrSubstNo(UnknownToolErr, ToolName);
                IsError := true;
            end;

            Clear(ToolResultMsg);
            ToolResultMsg.Add('role', 'tool');
            ToolResultMsg.Add('tool_call_id', ToolCallId);
            ToolResultMsg.Add('content', ResultText);
            Messages.Add(ToolResultMsg);
        end;
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
}
