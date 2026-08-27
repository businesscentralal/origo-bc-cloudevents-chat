namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Registers three LLM provider variants on the Core "MCP Chat Role Prov. ori" enum.
/// Each value uses a different authentication scheme for the HTTP endpoint.
/// </summary>
enumextension 10035488 "CE LLM Role Prov." extends "MCP Chat Role Prov. ori"
{
    value(10035485; "OpenAI")
    {
        Caption = 'OpenAI', Comment = 'is-IS=OpenAI';
        Implementation = "MCP Chat Role Provider ori" = "CE LLM OpenAI Impl ori";
    }
    value(10035486; "Azure OpenAI")
    {
        Caption = 'Azure OpenAI', Comment = 'is-IS=Azure OpenAI';
        Implementation = "MCP Chat Role Provider ori" = "CE LLM Azure OAI Impl ori";
    }
    value(10035487; "Custom LLM")
    {
        Caption = 'Custom LLM', Comment = 'is-IS=Sérsniðið LLM';
        Implementation = "MCP Chat Role Provider ori" = "CE LLM Custom Impl ori";
    }
}
