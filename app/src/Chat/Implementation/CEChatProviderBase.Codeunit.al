namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

codeunit 10035501 "CE Chat Provider Base ori"
{
    Access = Internal;

    var
        HttpClientBlockedMsg: Label 'HttpClient calls are blocked in this environment. An administrator must allow AL HttpClient requests.', Comment = 'is-IS=HttpClient köll eru lokuð í þessu umhverfi. Stjórnandi þarf að leyfa AL HttpClient beiðnir.';
        ServiceGateDeniedErr: Label 'LLM is not configured. Set up an MCP Chat Role with a Chat Provider.', Comment = 'is-IS=LLM er ekki uppsett. Settu upp MCP spjallhlutverk með spjallveitanda.';

    internal procedure HasServiceKeyPermission(): Boolean
    var
        ServiceGate: Record "CE Chat Service Gate ori";
    begin
        exit(ServiceGate.WritePermission());
    end;

    internal procedure GetBaseUrl(var Argument: Record "MCP Chat Argument ori" temporary; DefaultUrl: Text): Text
    begin
        if Argument."Base URL" <> '' then
            exit(Argument."Base URL");
        exit(DefaultUrl);
    end;

    internal procedure GetModel(var Argument: Record "MCP Chat Argument ori" temporary; DefaultModel: Text): Text
    begin
        if Argument.Model <> '' then
            exit(Argument.Model);
        exit(DefaultModel);
    end;

    internal procedure GetTimeoutMs(var Argument: Record "MCP Chat Argument ori" temporary; DefaultMs: Integer): Integer
    begin
        if Argument."Timeout Ms" > 0 then
            exit(Argument."Timeout Ms");
        exit(DefaultMs);
    end;

    internal procedure GetMaxTokens(var Argument: Record "MCP Chat Argument ori" temporary; DefaultMaxTokens: Integer): Integer
    begin
        if Argument."Max Tokens" > 0 then
            exit(Argument."Max Tokens");
        exit(DefaultMaxTokens);
    end;

    [NonDebuggable]
    internal procedure IsConfigured(var Argument: Record "MCP Chat Argument ori" temporary; DefaultBaseUrl: Text): Boolean
    begin
        if Argument.GetApiKey() = '' then
            exit(false);
        exit(GetBaseUrl(Argument, DefaultBaseUrl) <> '');
    end;

    /// <summary>
    /// Parses OpenAI-format token usage from a response JSON string.
    /// </summary>
    internal procedure ParseTokenUsage(ResponseJson: Text; var InputTokens: Integer; var OutputTokens: Integer)
    var
        ResponseObject: JsonObject;
        UsageToken: JsonToken;
        UsageObject: JsonObject;
        PromptToken: JsonToken;
        CompletionToken: JsonToken;
    begin
        InputTokens := 0;
        OutputTokens := 0;
        if not ResponseObject.ReadFrom(ResponseJson) then
            exit;
        if not ResponseObject.Get('usage', UsageToken) then
            exit;
        if not UsageToken.IsObject() then
            exit;
        UsageObject := UsageToken.AsObject();
        if UsageObject.Get('prompt_tokens', PromptToken) then
            InputTokens := PromptToken.AsValue().AsInteger();
        if UsageObject.Get('completion_tokens', CompletionToken) then
            OutputTokens := CompletionToken.AsValue().AsInteger();
    end;

    /// <summary>
    /// Returns whether any MCP Chat Role is configured with an external LLM provider.
    /// </summary>
    internal procedure HasServiceGate(): Boolean
    var
        MCPChatRole: Record "MCP Chat Role ori";
    begin
        MCPChatRole.SetFilter("Chat Provider", '<>%1', MCPChatRole."Chat Provider"::None);
        exit(not MCPChatRole.IsEmpty());
    end;

    /// <summary>
    /// Asserts the service gate and responds with error if no LLM provider is configured.
    /// </summary>
    internal procedure AssertServiceGate(var Argument: Record "CE Message Argument ori"): Boolean
    begin
        if HasServiceGate() then
            exit(true);
        Argument.RespondWithError(ServiceGateDeniedErr);
        exit(false);
    end;

    /// <summary>
    /// Raises an error if HttpClient is not allowed in this environment.
    /// </summary>
    internal procedure EnsureHttpClientAllowed()
    begin
        if not CanSendHttpRequests() then
            Error(HttpClientBlockedMsg);
    end;

    local procedure CanSendHttpRequests(): Boolean
    var
        Handled: Boolean;
        Allowed: Boolean;
    begin
        OnCheckHttpClientAllowed(Handled, Allowed);
        if Handled then
            exit(Allowed);
        exit(true);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheckHttpClientAllowed(var Handled: Boolean; var Allowed: Boolean)
    begin
    end;

    /// <summary>
    /// If the payload contains a files array, converts the last user message
    /// from plain text to a multi-modal content array (OpenAI format).
    /// </summary>
    internal procedure AttachFilesToMessages(PayloadObject: JsonObject; var Messages: JsonArray)
    var
        FilesToken: JsonToken;
        FilesArray: JsonArray;
        FileToken: JsonToken;
        ContentArray: JsonArray;
        TextBlock: JsonObject;
        FileBlock: JsonObject;
        LastToken: JsonToken;
        LastMessage: JsonObject;
        NewMessage: JsonObject;
        UserText: Text;
        LastIndex: Integer;
    begin
        if not PayloadObject.Get('files', FilesToken) then
            exit;
        if not FilesToken.IsArray() then
            exit;
        FilesArray := FilesToken.AsArray();
        if FilesArray.Count() = 0 then
            exit;

        LastIndex := Messages.Count() - 1;
        if LastIndex < 0 then
            exit;
        Messages.Get(LastIndex, LastToken);
        if not LastToken.IsObject() then
            exit;
        LastMessage := LastToken.AsObject();

        UserText := GetJsonTextInternal(LastMessage, 'content');
        TextBlock.Add('type', 'text');
        TextBlock.Add('text', UserText);
        ContentArray.Add(TextBlock);

        foreach FileToken in FilesArray do
            if FileToken.IsObject() then begin
                FileBlock := BuildOpenAIFileBlock(FileToken.AsObject());
                ContentArray.Add(FileBlock);
                Clear(FileBlock);
            end;

        // Replace the last message — JsonArray.Get returns a copy, not a reference
        Messages.RemoveAt(LastIndex);
        NewMessage.Add('role', 'user');
        NewMessage.Add('content', ContentArray);
        Messages.Add(NewMessage);
    end;

    local procedure BuildOpenAIFileBlock(FileObj: JsonObject) Block: JsonObject
    var
        DataUriTok: Label 'data:%1;base64,%2', Locked = true;
        ImageUrl: JsonObject;
        FileContent: JsonObject;
        MimeType: Text;
        DataUri: Text;
    begin
        MimeType := GetJsonTextInternal(FileObj, 'mimeType');
        DataUri := StrSubstNo(DataUriTok, MimeType, GetJsonTextInternal(FileObj, 'data'));

        if MimeType.StartsWith('image/') then begin
            ImageUrl.Add('url', DataUri);
            Block.Add('type', 'image_url');
            Block.Add('image_url', ImageUrl);
        end else begin
            FileContent.Add('filename', GetJsonTextInternal(FileObj, 'fileName'));
            FileContent.Add('file_data', DataUri);
            Block.Add('type', 'file');
            Block.Add('file', FileContent);
        end;
    end;

    local procedure GetJsonTextInternal(JObject: JsonObject; PropertyName: Text): Text
    var
        JToken: JsonToken;
    begin
        if JObject.Get(PropertyName, JToken) then
            if JToken.IsValue() then
                exit(JToken.AsValue().AsText());
    end;
}
