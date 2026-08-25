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
    var
        SchemeEnd: Integer;
        DomainEnd: Integer;
        UrlAfterScheme: Text;
    begin
        if FullUrl = '' then
            exit('');
        SchemeEnd := StrPos(FullUrl, '://');
        if SchemeEnd = 0 then
            exit(FullUrl);
        UrlAfterScheme := CopyStr(FullUrl, SchemeEnd + 3);
        DomainEnd := StrPos(UrlAfterScheme, '/');
        if DomainEnd = 0 then
            exit(FullUrl);
        exit(CopyStr(FullUrl, 1, SchemeEnd + 2 + DomainEnd - 1));
    end;
}
