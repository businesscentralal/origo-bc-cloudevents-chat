namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Masker for LLM API requests. Strips API keys from request bodies;
/// passes full bodies in debug mode, redacts in normal mode.
/// </summary>
codeunit 10035496 "CE LLM Req Log Masker ori" implements "CE Request Log Masker ori"
{
    Access = Internal;

    var
        RedactedTok: Label '***REDACTED***', Locked = true;

    procedure MaskRequestBody(Body: Text; DebugMode: Boolean): Text
    begin
        if DebugMode then
            exit(Body);
        exit(RedactedTok);
    end;

    procedure MaskResponseBody(Body: Text; DebugMode: Boolean): Text
    begin
        if DebugMode then
            exit(Body);
        exit(RedactedTok);
    end;

    procedure MaskErrorText(ErrorText: Text; DebugMode: Boolean): Text
    begin
        exit(ErrorText);
    end;

    procedure GetBaseUrl(FullUrl: Text): Text
    begin
        exit('https://llm.kappi.is');
    end;
}
