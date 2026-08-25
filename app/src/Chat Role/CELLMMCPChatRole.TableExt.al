namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Extends MCP Chat Role with the LLM Model field for selecting the AI model.
/// </summary>
tableextension 10035486 "CE LLM MCP Chat Role ori" extends "MCP Chat Role ori"
{
    fields
    {
        field(10035485; "CE LLM Model ori"; Text[50])
        {
            Caption = 'LLM Model', Comment = 'is-IS=LLM líkan';
            DataClassification = CustomerContent;

            trigger OnValidate()
            var
                TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
            begin
                if Rec."CE LLM Model ori" = '' then
                    exit;

                if not LLMChatSetup.GetAvailableModels(TempNameValueBuffer) then
                    exit; // cannot reach API — allow any value

                TempNameValueBuffer.SetRange(Name, Rec."CE LLM Model ori");
                if TempNameValueBuffer.IsEmpty() then
                    Error(InvalidModelErr, Rec."CE LLM Model ori");
            end;
        }
        field(10035486; "CE LLM Provider Code ori"; Code[20])
        {
            Caption = 'LLM Provider', Comment = 'is-IS=LLM veita';
            DataClassification = CustomerContent;
            TableRelation = "CE LLM Provider Setup ori".Code where(Enabled = const(true));
        }
    }

    var
        InvalidModelErr: Label 'Model ''%1'' is not a valid model. Use the lookup to see available models.', Comment = '%1 = model id, is-IS=Líkan ''%1'' er ekki gilt líkan. Notaðu uppflettingu til að sjá tiltæk líkön.';
}
