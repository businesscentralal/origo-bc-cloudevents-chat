namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

/// <summary>
/// Registers LLM provider variants on the Core "MCP Chat Role Prov. ori" enum.
/// Each value uses a different authentication scheme for the HTTP endpoint.
/// </summary>
enumextension 10035488 "CE Chat Role Prov. ori" extends "MCP Chat Role Prov. ori"
{
    value(10035485; "OpenAI")
    {
        Caption = 'OpenAI', Comment = 'is-IS=OpenAI';
        Implementation = "MCP Chat Role Provider ori" = "CE Chat OpenAI Impl ori";
    }
    value(10035486; "Azure OpenAI")
    {
        Caption = 'Azure OpenAI', Comment = 'is-IS=Azure OpenAI';
        Implementation = "MCP Chat Role Provider ori" = "CE Chat Azure OAI Impl ori";
    }
    value(10035487; "Custom LLM")
    {
        Caption = 'Custom LLM', Comment = 'is-IS=Sérsniðið LLM';
        Implementation = "MCP Chat Role Provider ori" = "CE Chat Custom Impl ori";
    }
    value(10035488; "Anthropic")
    {
        Caption = 'Anthropic', Comment = 'is-IS=Anthropic';
        Implementation = "MCP Chat Role Provider ori" = "CE Chat Anthropic Impl ori";
    }
    value(10035489; "xAI")
    {
        Caption = 'xAI (Grok)', Comment = 'is-IS=xAI (Grok)';
        Implementation = "MCP Chat Role Provider ori" = "CE Chat xAI Impl ori";
    }
    value(10035490; "Google")
    {
        Caption = 'Google (Gemini)', Comment = 'is-IS=Google (Gemini)';
        Implementation = "MCP Chat Role Provider ori" = "CE Chat Gemini Impl ori";
    }
}
