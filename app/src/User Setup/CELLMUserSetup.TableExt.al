namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends CE User Setup with the user's preferred LLM provider.
/// Used as fallback when the Chat Role doesn't specify a provider.
/// </summary>
tableextension 10035487 "CE LLM User Setup ori" extends "CE User Setup ori"
{
    fields
    {
        field(10035485; "CE LLM Provider Code ori"; Code[20])
        {
            Caption = 'LLM Provider', Comment = 'is-IS=LLM veita';
            DataClassification = CustomerContent;
            TableRelation = "CE LLM Provider Setup ori".Code where(Enabled = const(true));
        }
    }
}
