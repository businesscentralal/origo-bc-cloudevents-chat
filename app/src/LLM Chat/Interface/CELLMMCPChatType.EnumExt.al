namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Registers the LLM provider as a value on the base "MCP Chat Type" enum
/// and binds it to the LLM implementation of the "MCP Chat Provider" interface.
/// </summary>
enumextension 10035485 "CE LLM MCP Chat Type ori" extends "MCP Chat Type ori"
{
    /// <summary>
    /// Self-hosted LLM chat provider (OpenAI-compatible).
    /// </summary>
    value(10035485; LLM)
    {
        Caption = 'LLM', Comment = 'is-IS=LLM';
        Implementation = "MCP Chat Provider ori" = "CE LLM Chat Prov Impl ori";
    }
}
