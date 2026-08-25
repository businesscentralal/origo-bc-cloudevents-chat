namespace Origo.APP.CloudEvents.LLM;

using Origo.APP.CloudEvents;

/// <summary>
/// Extends the CE User Setup Editor page with LLM-specific status fields
/// and clear-credentials actions.
/// </summary>
pageextension 10035486 "CE LLM Chat User SetEd ori" extends "CE User Setup Editor ori"
{
    layout
    {
        addafter(LinkedRecords)
        {
            group(ori_LLMChatStatus)
            {
                Caption = 'LLM Chat', Comment = 'is-IS=LLM-spjall';

                field(ori_HasApiKey; HasApiKeyValue)
                {
                    ApplicationArea = All;
                    Caption = 'LLM API Key', Comment = 'is-IS=LLM API lykill';
                    ToolTip = 'Indicates whether this user has an LLM API key configured.', Comment = 'is-IS=Gefur til kynna hvort notandinn sé með LLM API lykil stilltan.';
                    Editable = false;
                }
            }
        }
    }

    actions
    {
        addlast(Processing)
        {
            action(ori_ClearApiKey)
            {
                ApplicationArea = All;
                Caption = 'Clear API Key', Comment = 'is-IS=Hreinsa API-lykil';
                ToolTip = 'Removes the stored LLM API key for this user.', Comment = 'is-IS=Fjarlægir vistaðan LLM API-lykil fyrir þennan notanda.';
                Image = DeleteQtyToHandle;

                trigger OnAction()
                begin
                    LLMChatSetup.ClearApiKey();
                    HasApiKeyValue := false;
                    CurrPage.Update(false);
                    Message(ApiKeyClearedMsg);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        HasApiKeyValue := LLMChatSetup.HasApiKey();
    end;

    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        HasApiKeyValue: Boolean;
        ApiKeyClearedMsg: Label 'API key cleared.', Comment = 'is-IS=API-lykill hreinsaður.';
}
