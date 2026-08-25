namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Auth config for Azure AI Foundry (Models as a Service) using api-key header.
/// Chat/models paths are standard; timeout is lower since Azure endpoints are fast.
/// </summary>
codeunit 10035500 "CE LLM Auth Azure ori" implements "CE LLM Auth Config ori"
{
    Access = Internal;

    procedure GetDefaultBaseUrl(): Text[250]
    begin
        exit('');
    end;

    procedure GetDefaultChatPath(): Text[100]
    begin
        exit('/v1/chat/completions');
    end;

    procedure GetDefaultModelsPath(): Text[100]
    begin
        exit('/v1/models');
    end;

    procedure GetDefaultTimeout(): Integer
    begin
        exit(120);
    end;

    procedure GetDefaultMaxTokens(): Integer
    begin
        exit(4096);
    end;

    procedure GetDefaultModel(): Text[100]
    begin
        exit('');
    end;

    procedure ShowBaseUrl(): Boolean
    begin
        exit(true);
    end;

    procedure ShowChatPath(): Boolean
    begin
        exit(true);
    end;

    procedure ShowModelsPath(): Boolean
    begin
        exit(true);
    end;

    procedure SupportsModelLookup(): Boolean
    begin
        exit(true);
    end;

    [NonDebuggable]
    procedure AddAuthHeader(var HttpClient: HttpClient; ApiKey: Text)
    var
        Headers: HttpHeaders;
    begin
        Headers := HttpClient.DefaultRequestHeaders();
        Headers.Add('api-key', ApiKey);
    end;
}
