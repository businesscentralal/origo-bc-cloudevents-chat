namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Test handler codeunit for mocking LLM API HTTP responses.
/// Subscribes to the LLM API Client's OnBeforeSendRequest event to intercept the
/// outgoing call and return a canned response (or simulate a failure) without network access.
/// </summary>
codeunit 95900 "CE LLM AI Handler ori"
{
    EventSubscriberInstance = Manual;
    SingleInstance = true;

    var
        GlobalResponseMessage: HttpResponseMessage;
        FailWithError: Boolean;
        ErrorMessageText: Text;
        LastRequestUrl: Text;

    /// <summary>
    /// Sets the mock HTTP response content for the next API call (success).
    /// </summary>
    internal procedure SetResponse(Response: Text)
    begin
        FailWithError := false;
        GlobalResponseMessage.Content.WriteFrom(Response);
    end;

    /// <summary>
    /// Configures the next API call to fail, simulating an LLM API/transport error.
    /// </summary>
    internal procedure SetErrorResponse(ErrorMsg: Text)
    begin
        FailWithError := true;
        ErrorMessageText := ErrorMsg;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CE LLM API Client ori", 'OnBeforeSendRequest', '', false, false)]
    local procedure OnBeforeSendRequest(var Content: HttpContent; var ResponseMessage: HttpResponseMessage; var IsHandled: Boolean)
    begin
        IsHandled := true;
        if FailWithError then
            Error(ErrorMessageText);
        ResponseMessage := GlobalResponseMessage;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CE LLM API Client ori", 'OnBeforeSendModelsRequest', '', false, false)]
    local procedure OnBeforeSendModelsRequest(var RequestUrl: Text; var ResponseMessage: HttpResponseMessage; var IsHandled: Boolean)
    begin
        IsHandled := true;
        LastRequestUrl := RequestUrl;
        if FailWithError then
            Error(ErrorMessageText);
        ResponseMessage := GlobalResponseMessage;
    end;

    /// <summary>
    /// Returns the URL captured by the last intercepted models request.
    /// </summary>
    internal procedure GetLastRequestUrl(): Text
    begin
        exit(LastRequestUrl);
    end;
}
