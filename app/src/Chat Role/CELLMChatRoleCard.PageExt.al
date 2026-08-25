namespace Origo.APP.CloudEvents.LLM;

using Microsoft.Utilities;
using Origo.APP.CloudEvents;

/// <summary>
/// Extends the MCP Chat Role Card with the LLM Model field and lookup.
/// </summary>
pageextension 10035487 "CE LLM ChatRole Card ori" extends "MCP Chat Role Card ori"
{
    layout
    {
        addafter(Description)
        {
            field(ori_LLMProvider; Rec."CE LLM Provider Code ori")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the LLM provider to use for this role. Leave blank to use the default provider.', Comment = 'is-IS=Tilgreinir LLM veitu fyrir þetta hlutverk. Skildu eftir autt til að nota sjálfgefna veitu.';
            }
            field(ori_LLMModel; Rec."CE LLM Model ori")
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the LLM model to use for this role (e.g. qwen3:8b). Leave blank to use the server default.', Comment = 'is-IS=Tilgreinir LLM líkanið sem nota á fyrir þetta hlutverk. Skildu eftir autt til að nota sjálfgefið líkan þjónsins.';

                trigger OnLookup(var Text: Text): Boolean
                var
                    TempNameValueBuffer: Record "Name/Value Buffer" temporary;
                    LLMChatSetup: Codeunit "CE LLM Chat Setup ori";
                    ModelList: Page "MCP Chat Model List ori";
                begin
                    LLMChatSetup.EnsureHttpClientAllowed();
                    if not LLMChatSetup.GetAvailableModels(TempNameValueBuffer) then
                        exit(false);

                    if Text <> '' then begin
                        TempNameValueBuffer.SetRange(Name, Text);
                        if TempNameValueBuffer.FindFirst() then;
                        TempNameValueBuffer.SetRange(Name);
                    end;

                    ModelList.Set(TempNameValueBuffer);
                    ModelList.LookupMode := true;
                    if ModelList.RunModal() = Action::LookupOK then begin
                        ModelList.GetRecord(TempNameValueBuffer);
                        Text := TempNameValueBuffer.Name;
                        exit(true);
                    end;
                end;
            }
        }
    }
}
