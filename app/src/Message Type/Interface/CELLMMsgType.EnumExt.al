namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Event Message Type enum with LLM message types.
/// </summary>
enumextension 10035486 "CE LLM Msg Type ori" extends "Cloud Event Message Type ori"
{
    /// <summary>
    /// Sends a prompt to a named LLM model via OpenAI-compatible Chat Completions API and returns the assistant text.
    /// Optionally exposes selected Cloud Events message types to the model as tools and runs a tool loop.
    /// </summary>
    value(10035485; "LLM.Model.Call")
    {
        Caption = 'LLM.Model.Call', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "CE LLM Model Call Impl ori";
    }

    /// <summary>
    /// Lists the LLM models available on the configured endpoint.
    /// </summary>
    value(10035486; "LLM.Model.List")
    {
        Caption = 'LLM.Model.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "CE LLM Model List Impl ori";
    }
}
