namespace Origo.APP.CloudEvents.Chat;

using Origo.APP.CloudEvents;

/// <summary>
/// Adds an LLM log type to the shared request log enum.
/// </summary>
enumextension 10035487 "CE Chat Request Log Type ori" extends "CE Request Log Type ori"
{
    value(10035485; "LLM ori")
    {
        Caption = 'LLM', Comment = 'is-IS=LLM';
        Implementation = "CE Request Log Masker ori" = "CE Chat Req Log Masker ori";
    }
}
