namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Calls the OpenAI-compatible Chat Completions API on the configured LLM endpoint
/// for unattended, server-side scenarios (such as Cloud Events chain steps).
/// Uses the encrypted service API key from setup.
/// </summary>
codeunit 10035485 "CE LLM API Client ori"
{
    Access = Internal;

    var
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
        ChatEndpointTok: Label '%1/v1/chat/completions', Locked = true;
        ModelsEndpointTok: Label '%1/v1/models', Locked = true;
        ServiceNameTok: Label 'LLM', Locked = true;
        CallFailedErr: Label 'Could not reach the LLM API. %1', Comment = '%1 = error detail, is-IS=Náði ekki sambandi við LLM API. %1';
        ApiStatusErr: Label 'LLM API returned status %1. %2', Comment = '%1 = status code, %2 = detail, is-IS=LLM API skilaði stöðu %1. %2';
        InvalidResponseErr: Label 'Received an invalid response from the LLM API.', Comment = 'is-IS=Ógilt svar barst frá LLM API.';

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
            LastOperation, LastHttpMethod, LastRequestUrl, ServiceNameTok,
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
            RequestBody.Add('max_tokens', ResolveMaxTokens(MaxTokens));

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
        CloudEventsSetup: Record "Cloud Events Setup ori";
        HttpClientVar: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        DefaultHeaders: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        RequestUrl: Text;
        StartTime: DateTime;
        IsHandled: Boolean;
    begin
        HasPendingLog := false;
        RequestBody.WriteTo(RequestText);
        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        OnBeforeSendRequest(HttpContent, HttpResponse, IsHandled);
        if not IsHandled then begin
            if ApiKey = '' then
                ApiKey := GetServiceApiKey();
            DefaultHeaders := HttpClientVar.DefaultRequestHeaders();
            DefaultHeaders.Add('x-api-key', ApiKey);
            HttpClientVar.Timeout(CloudEventsSetup.GetLLMTimeoutMs());

            RequestUrl := StrSubstNo(ChatEndpointTok, CloudEventsSetup.GetLLMBaseUrl());
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
    local procedure GetServiceApiKey(): Text
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        exit(CloudEventsSetup.GetLLMServiceApiKey());
    end;

    /// <summary>
    /// Retrieves the models available from the LLM endpoint's /v1/models API.
    /// </summary>
    [NonDebuggable]
    procedure ListModels() Models: JsonArray
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
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
        HasPendingLog := false;
        RequestUrl := StrSubstNo(ModelsEndpointTok, CloudEventsSetup.GetLLMBaseUrl());

        OnBeforeSendModelsRequest(RequestUrl, HttpResponse, IsHandled);
        if not IsHandled then begin
            DefaultHeaders := HttpClient.DefaultRequestHeaders();
            DefaultHeaders.Add('x-api-key', CloudEventsSetup.GetLLMServiceApiKey());

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
    /// Sends a chat completion using a specific provider configuration.
    /// </summary>
    [NonDebuggable]
    procedure SendForProvider(var ProviderSetup: Record "CE LLM Provider Setup ori"; RequestBody: JsonObject; ApiKey: Text) Response: JsonObject
    var
        HttpClientVar: HttpClient;
        HttpContent: HttpContent;
        HttpResponse: HttpResponseMessage;
        ContentHeaders: HttpHeaders;
        RequestText: Text;
        ResponseText: Text;
        RequestUrl: Text;
        StartTime: DateTime;
    begin
        HasPendingLog := false;
        RequestBody.WriteTo(RequestText);
        HttpContent.WriteFrom(RequestText);
        HttpContent.GetHeaders(ContentHeaders);
        if ContentHeaders.Contains('Content-Type') then
            ContentHeaders.Remove('Content-Type');
        ContentHeaders.Add('Content-Type', 'application/json');

        if ApiKey = '' then
            ApiKey := ProviderSetup.GetApiKey();

        ProviderSetup.ApplyAuthHeader(HttpClientVar, ApiKey);
        HttpClientVar.Timeout(ProviderSetup.GetTimeoutMs());

        RequestUrl := ProviderSetup.GetChatUrl();
        StartTime := CurrentDateTime();
        if not HttpClientVar.Post(RequestUrl, HttpContent, HttpResponse) then begin
            BufferLog('chat/completions', 'POST', RequestUrl, RequestText, '',
                GetLastErrorText(), 0, CurrentDateTime() - StartTime, false);
            Error(CallFailedErr, GetLastErrorText());
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

    /// <summary>
    /// Lists models available on a specific provider.
    /// </summary>
    [NonDebuggable]
    procedure ListModelsForProvider(var ProviderSetup: Record "CE LLM Provider Setup ori") Models: JsonArray
    var
        HttpClient: HttpClient;
        HttpResponse: HttpResponseMessage;
        Response: JsonObject;
        DataToken: JsonToken;
        RequestUrl: Text;
        ResponseText: Text;
        ApiKey: Text;
    begin
        ApiKey := ProviderSetup.GetApiKey();
        RequestUrl := ProviderSetup.GetModelsUrl();

        ProviderSetup.ApplyAuthHeader(HttpClient, ApiKey);

        if not HttpClient.Get(RequestUrl, HttpResponse) then
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
    var
        CloudEventsSetup: Record "Cloud Events Setup ori";
    begin
        if Model <> '' then
            exit(Model);
        exit(CloudEventsSetup.GetLLMDefaultModel());
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
