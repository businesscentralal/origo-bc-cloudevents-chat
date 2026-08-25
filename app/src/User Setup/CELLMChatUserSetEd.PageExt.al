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

                field(ori_LLMProvider; Rec."CE LLM Provider Code ori")
                {
                    ApplicationArea = All;
                    ToolTip = 'Specifies the default LLM provider for this user. Overrides the global default but is overridden by the Chat Role provider.', Comment = 'is-IS=Tilgreinir sjálfgefna LLM veitu fyrir þennan notanda. Hnekkir almennu sjálfgefnu en er hnekkt af veitu spjallhlutverksins.';
                }
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
            action(ori_ClearLLMApiKey)
            {
                ApplicationArea = All;
                Caption = 'Clear LLM API Key', Comment = 'is-IS=Hreinsa LLM API-lykil';
                ToolTip = 'Removes the stored LLM API key for the selected provider.', Comment = 'is-IS=Fjarlægir vistaðan LLM API-lykil fyrir valda veitu.';
                Image = DeleteQtyToHandle;

                trigger OnAction()
                var
                    ProviderSetup: Record "CE LLM Provider Setup ori";
                begin
                    if LLMChatSetup.ResolveProvider(ProviderSetup) then begin
                        ProviderSetup.SetUserApiKey('');
                        HasApiKeyValue := false;
                        CurrPage.Update(false);
                        Message(ApiKeyClearedMsg, ProviderSetup.Name);
                    end else
                        Message(NoProviderMsg);
                end;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    var
        ProviderSetup: Record "CE LLM Provider Setup ori";
    begin
        if LLMChatSetup.ResolveProvider(ProviderSetup) then
            HasApiKeyValue := ProviderSetup.HasApiKey()
        else
            HasApiKeyValue := false;
    end;

    var
        LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
        HasApiKeyValue: Boolean;
        ApiKeyClearedMsg: Label 'LLM API key cleared for %1.', Comment = '%1 = provider name, is-IS=LLM API-lykill hreinsaður fyrir %1.';
        NoProviderMsg: Label 'No LLM provider configured. Set a provider on this user or in Cloud Events Setup.', Comment = 'is-IS=Engin LLM veita stillt. Stilltu veitu á þessum notanda eða í Uppsetningu atburða í skýinu.';
}
