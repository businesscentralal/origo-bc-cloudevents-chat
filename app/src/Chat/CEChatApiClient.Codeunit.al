namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;
using System.Environment;
using System.Environment.Configuration;

/// <summary>
/// Calls the OpenAI-compatible Chat Completions API on the configured LLM endpoint
/// for unattended, server-side scenarios (such as Cloud Events chain steps).
/// Uses the encrypted service API key from setup.
/// </summary>
codeunit 10035485 "CE Chat API Client ori"
{
    Access = Internal;

    var
        MockResponseText: Text;
        MockErrorText: Text;
        IsMockMode: Boolean;
        IsMockError: Boolean;
        LastOperation: Text[50];
        LastHttpMethod: Text[10];
        LastRequestUrl: Text;
        LastRequestText: Text;
        LastResponseText: Text;
        LastErrorText: Text;
        LastHttpStatus: Integer;
        LastElapsed: Duration;
        LastIsSuccess: Boolean;
        HasPendingLog: Boolean;
        LastServiceName: Text[50];
        ChatEndpointTok: Label '%1/v1/chat/completions', Locked = true;
        ModelsEndpointTok: Label '%1/v1/models', Locked = true;
        ServiceNameTok: Label 'LLM', Locked = true;
        CallFailedErr: Label 'Could not reach the LLM API. %1', Comment = '%1 = error detail, is-IS=Náði ekki sambandi við LLM API. %1';
        ApiStatusErr: Label 'LLM API returned status %1. %2', Comment = '%1 = status code, %2 = detail, is-IS=LLM API skilaði stöðu %1. %2';
        InvalidResponseErr: Label 'Received an invalid response from the LLM API.', Comment = 'is-IS=Ógilt svar barst frá LLM API.';

    /// <summary>
    /// Enables mock mode for testing. All API calls return this response without HTTP.
    /// </summary>
    internal procedure SetMockResponse(ResponseJson: Text)
    begin
        IsMockMode := true;
        IsMockError := false;
        MockResponseText := ResponseJson;
    end;

    /// <summary>
    /// Enables mock error mode. All API calls raise this error without HTTP.
    /// </summary>
    internal procedure SetMockError(ErrorMsg: Text)
    begin
        IsMockMode := true;
        IsMockError := true;
        MockErrorText := ErrorMsg;
    end;

    /// <summary>
    /// Writes the buffered log entry from the last API call to the Request Log
    /// via background session. Only logs when Request Debug Mode is enabled.
    /// </summary>
    procedure LogLastRequest()
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
        Logger: Codeunit "CE Request Logger ori";
    begin
        if not HasPendingLog then
            exit;
        HasPendingLog := false;

        CloudEventsSetup.SetLoadFields("Request Debug Mode");
        if not CloudEventsSetup.Get() then
            exit;
        if not CloudEventsSetup."Request Debug Mode" then
            exit;

        Logger.Log(
            LastOperation, LastHttpMethod, LastRequestUrl, LastServiceName,
            LastHttpStatus, LastElapsed, LastIsSuccess, LastErrorText,
            LastRequestText, LastResponseText,
            Enum::"CE Request Log Type ori"::"LLM ori");
        Logger.Insert();
    end;

    /// <summary>
    /// Sends a chat completion using the default model/system prompt and returns the text answer.
    /// </summary>
    [NonDebuggable]
    procedure Complete(SystemPrompt: Text; UserPrompt: Text): Text
    begin
        exit(Complete('', SystemPrompt, UserPrompt, 0));
    end;

    /// <summary>
    /// Sends a single-turn chat completion and returns the assistant text.
    /// </summary>
    [NonDebuggable]
    procedure Complete(Model: Text; SystemPrompt: Text; UserPrompt: Text; MaxTokens: Integer): Text
    var
        RequestBody: JsonObject;
        Messages: JsonArray;
        SystemMessage: JsonObject;
        UserMessage: JsonObject;
        Response: JsonObject;
    begin
        if SystemPrompt <> '' then begin
            SystemMessage.Add('role', 'system');
            SystemMessage.Add('content', SystemPrompt);
            Messages.Add(SystemMessage);
        end;

        UserMessage.Add('role', 'user');
        UserMessage.Add('content', UserPrompt);
        Messages.Add(UserMessage);

        RequestBody.Add('model', ResolveModel(Model));
        RequestBody.Add('messages', Messages);
        if ResolveMaxTokens(MaxTokens) > 0 then
            RequestBody.Add('max_completion_tokens', ResolveMaxTokens(MaxTokens));

        Response := SendChatCompletion(RequestBody);
        exit(ExtractText(Response));
    end;

    /// <summary>
    /// Posts a fully-formed Chat Completions request body and returns the parsed response object.
    /// Uses the service API key from setup.
    /// </summary>
    [NonDebuggable]
    procedure SendChatCompletion(RequestBody: JsonObject) Response: JsonObject
    begin
        Response := DoSendChatCompletion(RequestBody, '');
    end;

    /// <summary>
    /// Posts a fully-formed Chat Completions request body using a caller-supplied API key.
    /// </summary>
    [NonDebuggable]
    procedure SendChatCompletion(RequestBody: JsonObject; ApiKey: Text) Response: JsonObject
    begin
        Response := DoSendChatCompletion(RequestBody, ApiKey);
    end;

    [NonDebuggable]
    local procedure DoSendChatCompletion(RequestBody: JsonObject; ApiKey: Text) Response: JsonObject
    var
        MCPChatRole: Record "MCP Chat Role ori";
        HttpClientVar: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        DefaultHeaders: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        RequestUrl: Text;
        BaseUrl: Text;
        TimeoutMs: Integer;
        StartTime: DateTime;
        IsHandled: Boolean;
    begin
        LastServiceName := ServiceNameTok;
        if IsMockMode then begin
            if IsMockError then
                Error(MockErrorText);
            Response.ReadFrom(MockResponseText);
            exit;
        end;
        RequestBody.WriteTo(RequestText);
        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        OnBeforeSendRequest(HttpContent, HttpResponse, IsHandled);
        if not IsHandled then begin
            if ApiKey = '' then begin
                ResolveRole(MCPChatRole);
                ApiKey := ResolveApiKey(MCPChatRole.SystemId);
            end else
                ResolveRole(MCPChatRole);

            if MCPChatRole."Base URL" <> '' then
                BaseUrl := MCPChatRole."Base URL";
            if MCPChatRole."Timeout Seconds" > 0 then
                TimeoutMs := MCPChatRole."Timeout Seconds" * 1000
            else
                TimeoutMs := 120000;

            DefaultHeaders := HttpClientVar.DefaultRequestHeaders();
            DefaultHeaders.Add('x-api-key', ApiKey);
            HttpClientVar.Timeout(TimeoutMs);

            RequestUrl := StrSubstNo(ChatEndpointTok, BaseUrl);
            StartTime := CurrentDateTime();
            if not HttpClientVar.Post(RequestUrl, HttpContent, HttpResponse) then begin
                BufferLog('chat/completions', 'POST', RequestUrl, RequestText, '',
                    GetLastErrorText(), 0, CurrentDateTime() - StartTime, false);
                Error(CallFailedErr, GetLastErrorText());
            end;
        end;

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then begin
            BufferLog('chat/completions', 'POST', RequestUrl, RequestText, ResponseText,
                GetErrorDetail(ResponseText), HttpResponse.HttpStatusCode(), CurrentDateTime() - StartTime, false);
            Error(ApiStatusErr, Format(HttpResponse.HttpStatusCode()), GetErrorDetail(ResponseText));
        end;

        BufferLog('chat/completions', 'POST', RequestUrl, RequestText, ResponseText,
            '', HttpResponse.HttpStatusCode(), CurrentDateTime() - StartTime, true);

        if not Response.ReadFrom(ResponseText) then
            Error(InvalidResponseErr);
    end;

    [NonDebuggable]
    local procedure ResolveApiKey(RoleSystemId: Guid): Text
    var
        UserKeyPrefixTok: Label 'CE_LLM_Usr_', Locked = true;
        ServiceKeyTok: Label 'CE_LLM_Svc', Locked = true;
        ApiKeyValue: Text;
        StorageKey: Text;
    begin
        StorageKey := UserKeyPrefixTok + Format(RoleSystemId, 0, 4) + '_' + Format(UserSecurityId(), 0, 4);
        if IsolatedStorage.Get(StorageKey, DataScope::Company, ApiKeyValue) then
            if ApiKeyValue <> '' then
                exit(ApiKeyValue);
        StorageKey := ServiceKeyTok + '_' + Format(RoleSystemId, 0, 4);
        if IsolatedStorage.Get(StorageKey, DataScope::Company, ApiKeyValue) then
            exit(ApiKeyValue);
    end;

    local procedure ResolveRole(var MCPChatRole: Record "MCP Chat Role ori")
    var
        CEUserSetup: Record "CE User Setup ori";
        RoleCode: Code[20];
    begin
        CEUserSetup.SetLoadFields("MCP Chat Role Code");
        if CEUserSetup.Get(UserSecurityId()) then
            RoleCode := CEUserSetup."MCP Chat Role Code";
        if RoleCode <> '' then
            if MCPChatRole.Get(RoleCode) then
                exit;
        MCPChatRole.SetRange(Default, true);
        if MCPChatRole.FindFirst() then;
    end;

    /// <summary>
    /// Retrieves the models available from the LLM endpoint's /v1/models API.
    /// </summary>
    [NonDebuggable]
    procedure ListModels() Models: JsonArray
    var
        MCPChatRole: Record "MCP Chat Role ori";
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        DefaultHeaders: HttpHeaders;
        Response: JsonObject;
        DataToken: JsonToken;
        RequestUrl: Text;
        ResponseText: Text;
        StartTime: DateTime;
        IsHandled: Boolean;
    begin
        if IsMockMode then begin
            if IsMockError then
                Error(MockErrorText);
            Response.ReadFrom(MockResponseText);
            if Response.Get('data', DataToken) then
                if DataToken.IsArray() then
                    Models := DataToken.AsArray();
            exit;
        end;

        HasPendingLog := false;
        ResolveRole(MCPChatRole);
        if MCPChatRole."Base URL" <> '' then
            RequestUrl := StrSubstNo(ModelsEndpointTok, MCPChatRole."Base URL")
        else
            RequestUrl := StrSubstNo(ModelsEndpointTok, '');

        OnBeforeSendModelsRequest(RequestUrl, HttpResponse, IsHandled);
        if not IsHandled then begin
            DefaultHeaders := HttpClient.DefaultRequestHeaders();
            DefaultHeaders.Add('x-api-key', ResolveApiKey(MCPChatRole.SystemId));

            StartTime := CurrentDateTime();
            if not HttpClient.Get(RequestUrl, HttpResponse) then begin
                BufferLog('models', 'GET', RequestUrl, '', '',
                    GetLastErrorText(), 0, CurrentDateTime() - StartTime, false);
                Error(CallFailedErr, GetLastErrorText());
            end;
        end;

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then begin
            BufferLog('models', 'GET', RequestUrl, '', ResponseText,
                GetErrorDetail(ResponseText), HttpResponse.HttpStatusCode(), CurrentDateTime() - StartTime, false);
            Error(ApiStatusErr, Format(HttpResponse.HttpStatusCode()), GetErrorDetail(ResponseText));
        end;

        BufferLog('models', 'GET', RequestUrl, '', ResponseText,
            '', HttpResponse.HttpStatusCode(), CurrentDateTime() - StartTime, true);

        if not Response.ReadFrom(ResponseText) then
            Error(InvalidResponseErr);

        if Response.Get('data', DataToken) then
            if DataToken.IsArray() then
                Models := DataToken.AsArray();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendRequest(var Content: HttpContent; var ResponseMessage: HttpResponseMessage; var IsHandled: Boolean)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeSendModelsRequest(var RequestUrl: Text; var ResponseMessage: HttpResponseMessage; var IsHandled: Boolean)
    begin
    end;

    /// <summary>
    /// Sends a chat completion to an explicit endpoint URL with the specified auth.
    /// </summary>
    [NonDebuggable]
    procedure SendToEndpoint(ChatUrl: Text; AuthHeaderName: Text; ApiKey: Text; TimeoutMs: Integer; RequestBody: JsonObject) Response: JsonObject
    var
        HttpClientVar: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        DefaultHeaders: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        StartTime: DateTime;
    begin
        HasPendingLog := false;
        LastServiceName := ServiceNameTok;
        RequestBody.WriteTo(RequestText);
        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        DefaultHeaders := HttpClientVar.DefaultRequestHeaders();
        if AuthHeaderName = 'Authorization' then
            DefaultHeaders.Add('Authorization', 'Bearer ' + ApiKey)
        else
            DefaultHeaders.Add(AuthHeaderName, ApiKey);
        HttpClientVar.Timeout(TimeoutMs);

        StartTime := CurrentDateTime();
        if not HttpClientVar.Post(ChatUrl, HttpContent, HttpResponse) then begin
            BufferLog('chat/completions', 'POST', ChatUrl, RequestText, '',
                GetLastErrorText(), 0, CurrentDateTime() - StartTime, false);
            Error(CallFailedErr, GetLastErrorText());
        end;

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then begin
            BufferLog('chat/completions', 'POST', ChatUrl, RequestText, ResponseText,
                GetErrorDetail(ResponseText), HttpResponse.HttpStatusCode(), CurrentDateTime() - StartTime, false);
            Error(ApiStatusErr, Format(HttpResponse.HttpStatusCode()), GetErrorDetail(ResponseText));
        end;

        BufferLog('chat/completions', 'POST', ChatUrl, RequestText, ResponseText,
            '', HttpResponse.HttpStatusCode(), CurrentDateTime() - StartTime, true);

        if not Response.ReadFrom(ResponseText) then
            Error(InvalidResponseErr);
    end;

    /// <summary>
    /// Lists models from an explicit endpoint URL with the specified auth.
    /// </summary>
    [NonDebuggable]
    procedure ListModelsFromEndpoint(ModelsUrl: Text; AuthHeaderName: Text; ApiKey: Text) Models: JsonArray
    var
        HttpClientVar: HttpClient;
        HttpResponse: HttpResponseMessage;
        DefaultHeaders: HttpHeaders;
        Response: JsonObject;
        DataToken: JsonToken;
        ResponseText: Text;
    begin
        LastServiceName := ServiceNameTok;
        DefaultHeaders := HttpClientVar.DefaultRequestHeaders();
        if AuthHeaderName = 'Authorization' then
            DefaultHeaders.Add('Authorization', 'Bearer ' + ApiKey)
        else
            DefaultHeaders.Add(AuthHeaderName, ApiKey);

        if not HttpClientVar.Get(ModelsUrl, HttpResponse) then
            Error(CallFailedErr, GetLastErrorText());

        HttpResponse.Content.ReadAs(ResponseText);

        if not HttpResponse.IsSuccessStatusCode() then
            Error(ApiStatusErr, Format(HttpResponse.HttpStatusCode()), GetErrorDetail(ResponseText));

        if not Response.ReadFrom(ResponseText) then
            Error(InvalidResponseErr);

        if Response.Get('data', DataToken) then
            if DataToken.IsArray() then
                Models := DataToken.AsArray();
    end;



    /// <summary>
    /// Extracts the assistant text from an OpenAI-compatible chat completions response.
    /// </summary>
    procedure ExtractText(Response: JsonObject) ResultText: Text
    var
        ChoicesToken: JsonToken;
        FirstChoice: JsonToken;
        MessageToken: JsonToken;
        ContentToken: JsonToken;
    begin
        if not Response.Get('choices', ChoicesToken) then
            exit('');
        if not ChoicesToken.IsArray() then
            exit('');
        if ChoicesToken.AsArray().Count() = 0 then
            exit('');

        ChoicesToken.AsArray().Get(0, FirstChoice);
        if not FirstChoice.AsObject().Get('message', MessageToken) then
            exit('');
        if not MessageToken.AsObject().Get('content', ContentToken) then
            exit('');
        if ContentToken.IsValue() then
            ResultText := ContentToken.AsValue().AsText();
    end;

    local procedure ResolveModel(Model: Text): Text
    begin
        if Model <> '' then
            exit(Model);
        exit('gpt-4o');
    end;

    local procedure ResolveMaxTokens(MaxTokens: Integer): Integer
    begin
        if MaxTokens > 0 then
            exit(MaxTokens);
        exit(4096);
    end;

    local procedure GetErrorDetail(ResponseText: Text): Text
    var
        ErrorObject: JsonObject;
        ErrorToken: JsonToken;
        MessageToken: JsonToken;
    begin
        if ErrorObject.ReadFrom(ResponseText) then
            if ErrorObject.Get('error', ErrorToken) then
                if ErrorToken.AsObject().Get('message', MessageToken) then
                    exit(MessageToken.AsValue().AsText());
        exit(CopyStr(ResponseText, 1, 1000));
    end;

    local procedure BufferLog(Operation: Text[50]; HttpMethod: Text[10]; RequestUrl: Text; RequestText: Text; ResponseText: Text; ErrorText: Text; HttpStatus: Integer; Elapsed: Duration; IsSuccess: Boolean)
    begin
        LastOperation := Operation;
        LastHttpMethod := HttpMethod;
        LastRequestUrl := RequestUrl;
        LastRequestText := RequestText;
        LastResponseText := ResponseText;
        LastErrorText := ErrorText;
        LastHttpStatus := HttpStatus;
        LastElapsed := Elapsed;
        LastIsSuccess := IsSuccess;
        HasPendingLog := true;
    end;
}
