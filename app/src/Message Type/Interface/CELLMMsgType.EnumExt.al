namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the Cloud Event Message Type enum with LLM provider message types.
/// </summary>
enumextension 10035486 "CE LLM Msg Type ori" extends "Cloud Event Message Type ori"
{
    /// <summary>
    /// Returns the list of enabled LLM providers configured in the system.
    /// Use the returned provider codes in Provider.Model.List and Provider.Model.Call.
    /// </summary>
    value(10035487; "Provider.List")
    {
        Caption = 'Provider.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "CE LLM Provider List Impl ori";
    }

    /// <summary>
    /// Sends a prompt to a named LLM model via OpenAI-compatible Chat Completions API and returns the assistant text.
    /// Accepts a "provider" field in the payload to select the provider. Falls back to the default provider.
    /// Optionally exposes selected Cloud Events message types to the model as tools and runs a tool loop.
    /// </summary>
    value(10035485; "Provider.Model.Call")
    {
        Caption = 'Provider.Model.Call', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "CE LLM Model Call Impl ori";
    }

    /// <summary>
    /// Lists the models available on the specified (or default) LLM provider.
    /// Accepts a "provider" field in the payload to select the provider.
    /// </summary>
    value(10035486; "Provider.Model.List")
    {
        Caption = 'Provider.Model.List', Locked = true;
        Implementation = "Cloud Event Msg Interface ori" = "CE LLM Model List Impl ori";
    }
}
