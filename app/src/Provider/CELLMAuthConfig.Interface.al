namespace Origo.APP.CloudEvents.LLM;

/// <summary>
/// Contract for LLM provider auth type behavior.
/// Each Auth Type enum value implements this to supply defaults, control field visibility,
/// and handle the HTTP authentication header.
/// </summary>
interface "CE LLM Auth Config ori"
{
    /// <summary>Returns the default base URL for this auth type (empty = user must provide).</summary>
    procedure GetDefaultBaseUrl(): Text[250]

    /// <summary>Returns the default chat completions path.</summary>
    procedure GetDefaultChatPath(): Text[100]

    /// <summary>Returns the default models path.</summary>
    procedure GetDefaultModelsPath(): Text[100]

    /// <summary>Returns the default timeout in seconds.</summary>
    procedure GetDefaultTimeout(): Integer

    /// <summary>Returns the default max output tokens.</summary>
    procedure GetDefaultMaxTokens(): Integer

    /// <summary>Returns the default model name (empty = user must provide).</summary>
    procedure GetDefaultModel(): Text[100]

    /// <summary>Whether the Base URL field should be editable (false for fixed-URL providers).</summary>
    procedure ShowBaseUrl(): Boolean

    /// <summary>Whether the Chat Path field should be visible.</summary>
    procedure ShowChatPath(): Boolean

    /// <summary>Whether the Models Path field should be visible.</summary>
    procedure ShowModelsPath(): Boolean

    /// <summary>Whether the Test Connection / model lookup is supported.</summary>
    procedure SupportsModelLookup(): Boolean

    /// <summary>Adds the appropriate authorization header to the HTTP client.</summary>
    procedure AddAuthHeader(var HttpClient: HttpClient; ApiKey: Text)
}
