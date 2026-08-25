namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Specifies how the API key is sent to the LLM provider.
/// Each value implements CE LLM Auth Config ori to supply defaults and behavior.
/// </summary>
enum 10035485 "CE LLM Auth Type ori" implements "CE LLM Auth Config ori"
{
    Access = Public;
    Extensible = true;

    value(0; "x-api-key")
    {
        Caption = 'x-api-key (Reverse Proxy)', Comment = 'is-IS=x-api-key (öfugþjónn)';
        Implementation = "CE LLM Auth Config ori" = "CE LLM Auth XApiKey ori";
    }
    value(1; "Bearer")
    {
        Caption = 'Bearer (OpenAI-compatible)', Comment = 'is-IS=Bearer (OpenAI-samhæft)';
        Implementation = "CE LLM Auth Config ori" = "CE LLM Auth Bearer ori";
    }
    value(2; "api-key")
    {
        Caption = 'api-key (Azure)', Comment = 'is-IS=api-key (Azure)';
        Implementation = "CE LLM Auth Config ori" = "CE LLM Auth Azure ori";
    }
}
